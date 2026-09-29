# frozen_string_literal: true

require 'faraday'
require 'json'
require 'securerandom'
require 'uri'

module Sangho
  # Client HTTP de l'API Sangho : erreurs typées, retry avec backoff exponentiel sur 429 / 5xx / erreurs réseau
  # (miroir du HttpClient du SDK JS, core/http.ts).
  class HttpClient
    # Le backend distingue les clés de production ("prod") des clés de test ("test") : il n'existe pas de préfixe "live".
    VALID_PREFIXES = %w[pk_prod_ sk_prod_ pk_test_ sk_test_].freeze
    DEFAULT_BASE_URL = 'https://api.sangho.ga/v1'

    attr_reader :key_type, :sandbox

    # @param sleeper [#call] appelé avec le délai (secondes) avant chaque nouvel essai ; remplaçable dans les tests.
    def initialize(api_key:, base_url: DEFAULT_BASE_URL, timeout: 30, max_retries: 3, sleeper: Kernel.method(:sleep))
      validate_api_key!(api_key)
      validate_base_url!(base_url)

      @key_type = api_key.start_with?('pk_') ? :public : :secret
      @sandbox = api_key.start_with?('pk_test_', 'sk_test_')
      @timeout = timeout
      @max_retries = max_retries
      @sleeper = sleeper
      @conn = build_connection(api_key, base_url, timeout)
    end

    def assert_secret_key!(method)
      return unless @key_type == :public

      raise SanghoPublicKeyError,
            "Method `#{method}` requires a secret key (sk_…). You provided a public key (pk_…)."
    end

    def get(path, params = {})
      request(:get, path, params: params.compact)
    end

    def post(path, body = {}, idempotency_key: nil)
      request(:post, path, body: body, headers: { 'Idempotency-Key' => idempotency_key || SecureRandom.uuid })
    end

    def patch(path, body)
      request(:patch, path, body: body)
    end

    def put(path, body = {})
      request(:put, path, body: body)
    end

    def delete(path)
      request(:delete, path)
    end

    def options(path)
      request(:options, path)
    end

    private

    def validate_api_key!(api_key)
      raise ArgumentError, 'api_key must be a non-empty string.' unless api_key.is_a?(String) && !api_key.empty?
      unless VALID_PREFIXES.any? { |p| api_key.start_with?(p) }
        raise ArgumentError, "Invalid API key format. Keys must start with one of: #{VALID_PREFIXES.join(', ')}."
      end
      raise ArgumentError, 'API key is too short.' if api_key.length < 20
    end

    def validate_base_url!(base_url)
      uri = URI.parse(base_url)
      raise ArgumentError, "Invalid base_url: \"#{base_url}\"." unless uri.scheme && uri.host

      local = %w[localhost 127.0.0.1].include?(uri.host)
      return if uri.scheme == 'https' || local

      raise ArgumentError, "Refusing to send API keys over a non-HTTPS base_url: \"#{base_url}\". " \
                           'Use an https:// URL (localhost/127.0.0.1 are exempt for local development).'
    rescue URI::InvalidURIError
      raise ArgumentError, "Invalid base_url: \"#{base_url}\"."
    end

    def build_connection(api_key, base_url, timeout)
      environment = @sandbox ? 'sandbox' : 'live'
      Faraday.new(url: base_url) do |f|
        f.headers['Authorization'] = "Bearer #{api_key}"
        f.headers['Content-Type'] = 'application/json'
        f.headers['Accept'] = 'application/json'
        f.headers['User-Agent'] = "sangho-ruby/#{VERSION}"
        f.headers['X-Sangho-SDK'] = "ruby/#{VERSION}"
        f.headers['X-Sangho-Environment'] = environment
        f.options.timeout = timeout
        f.options.open_timeout = timeout
        f.adapter Faraday.default_adapter
      end
    end

    def request(method, path, params: {}, body: nil, headers: {})
      attempt = 0
      loop do
        begin
          resp = perform(method, path, params, body, headers)
        rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::SSLError => e
          raise transport_error(e) if attempt >= @max_retries
        else
          begin
            return handle(resp)
          rescue SanghoError => e
            raise unless retryable?(e) && attempt < @max_retries

            @sleeper.call(e.is_a?(SanghoRateLimitError) && e.retry_after ? e.retry_after : backoff(attempt))
            attempt += 1
            next
          end
        end
        @sleeper.call(backoff(attempt))
        attempt += 1
      end
    end

    # Un délai dépassé à la connexion est levé par Faraday comme une ConnectionFailed (Net::OpenTimeout) : c'est
    # quand même un timeout.
    def transport_error(error)
      timeout = error.is_a?(Faraday::TimeoutError) || error.wrapped_exception.is_a?(Timeout::Error)
      timeout ? SanghoTimeoutError.new(@timeout) : SanghoNetworkError.new(error.message)
    end

    def perform(method, path, params, body, headers)
      # Faraday ignore le préfixe de l'URL de base (« /v1 ») quand le chemin commence par « / » : on le retire.
      @conn.run_request(method, path.delete_prefix('/'), body.nil? ? nil : JSON.generate(body), headers) do |req|
        req.params.update(params) unless params.empty?
      end
    end

    # 429 et 5xx sont transitoires ; les autres 4xx (400/401/403/404/409/422) sont permanents : jamais de retry.
    def retryable?(error)
      error.is_a?(SanghoRateLimitError) || (error.status_code.is_a?(Integer) && error.status_code >= 500)
    end

    def backoff(attempt)
      (2**attempt) * 0.5
    end

    def handle(resp)
      return nil if resp.status == 204

      data = parse(resp.body)
      return data if resp.success?

      raise build_error(resp, data)
    end

    def parse(body)
      parsed = JSON.parse(body.to_s, symbolize_names: true)
      parsed.is_a?(Hash) || parsed.is_a?(Array) ? parsed : {}
    rescue JSON::ParserError
      {}
    end

    def build_error(resp, data)
      data = {} unless data.is_a?(Hash)
      status = resp.status
      msg = error_message(data)
      # Insensible à la casse : le backend envoie tantôt "PUBLIC_KEY_NOT_ALLOWED", tantôt "public_key_not_allowed".
      code = data[:code].to_s.downcase

      case status
      when 401 then SanghoAuthError.new(msg, raw: data)
      when 403
        code == 'public_key_not_allowed' ? SanghoPublicKeyError.new(msg, raw: data) : SanghoPermissionError.new(msg, raw: data)
      when 404 then SanghoNotFoundError.new(msg, raw: data)
      when 409 then SanghoIdempotencyError.new(raw: data)
      when 422 then SanghoValidationError.new(validation_message(data, msg), raw: data)
      when 429 then SanghoRateLimitError.new(data[:message], retry_after: retry_after(resp, data), raw: data)
      else SanghoError.new(msg, status_code: status, raw: data)
      end
    end

    def error_message(data)
      msg = data[:message] || data[:detail] || 'API error'
      msg.is_a?(String) ? msg : msg.to_s
    end

    def validation_message(data, fallback)
      fields = data[:detail].is_a?(Hash) ? data[:detail] : data[:errors]
      return fallback unless fields.is_a?(Hash) && !fields.empty?

      fields.map { |k, v| "#{k}: #{Array(v).join(', ')}" }.join(' | ')
    end

    def retry_after(resp, data)
      value = data[:retry_after] || resp.headers['Retry-After']
      value.to_s.match?(/\A\d+(\.\d+)?\z/) ? value.to_f.ceil : 60
    end
  end
end
