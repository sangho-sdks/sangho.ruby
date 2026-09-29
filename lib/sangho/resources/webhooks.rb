# frozen_string_literal: true

require 'json'
require 'openssl'

module Sangho
  module Resources
    # client.webhooks.{list, retrieve, create, update, delete, enable, disable, roll_secret, send_test_event,
    #                  list_deliveries, retrieve_delivery, retry_delivery, options}
    # Sangho::Resources::Webhooks.construct_event(payload, signature_header, secret) vérifie la signature d'un événement.
    class Webhooks < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('webhooks.list')
        @http.get('/webhooks/', criteria)
      end

      def retrieve(id)
        @http.assert_secret_key!('webhooks.retrieve')
        @http.get("/webhooks/#{id}/")
      end

      def create(url:, events:, **opts)
        @http.assert_secret_key!('webhooks.create')
        @http.post('/webhooks/', { url: url, events: events }.merge(opts))
      end

      def update(id, **payload)
        @http.assert_secret_key!('webhooks.update')
        @http.patch("/webhooks/#{id}/", payload)
      end

      def delete(id)
        @http.assert_secret_key!('webhooks.delete')
        @http.delete("/webhooks/#{id}/")
      end

      def disable(id)
        @http.assert_secret_key!('webhooks.disable')
        @http.post("/webhooks/#{id}/disable/")
      end

      def enable(id)
        @http.assert_secret_key!('webhooks.enable')
        @http.post("/webhooks/#{id}/enable/")
      end

      def roll_secret(id)
        @http.assert_secret_key!('webhooks.roll_secret')
        @http.post("/webhooks/#{id}/roll-secret/")
      end

      def send_test_event(id, type)
        @http.assert_secret_key!('webhooks.send_test_event')
        @http.post("/webhooks/#{id}/test/", { event_type: type })
      end

      def list_deliveries(id, **criteria)
        @http.assert_secret_key!('webhooks.list_deliveries')
        @http.get("/webhooks/#{id}/deliveries/", criteria)
      end

      def retrieve_delivery(id, delivery_id)
        @http.assert_secret_key!('webhooks.retrieve_delivery')
        @http.get("/webhooks/#{id}/deliveries/#{delivery_id}/")
      end

      def retry_delivery(id, delivery_id)
        @http.assert_secret_key!('webhooks.retry_delivery')
        @http.post("/webhooks/#{id}/deliveries/#{delivery_id}/retry/")
      end

      def options
        @http.options('/webhooks/')
      end

      # Vérifie la signature HMAC-SHA256 et retourne l'événement décodé.
      #
      # En-tête « Sangho-Signature: t=<ts>,v1=<hex>[,v1=<hex>…] », message signé « <ts>.<corps brut> ». Plusieurs +v1+
      # (et une liste de secrets) sont acceptés pour la rotation ; comparaison à temps constant. Passez le corps BRUT.
      #
      # @param secret [String, Array<String>] secret du webhook, ou liste de secrets pendant une rotation
      # @raise [SanghoWebhookSignatureError] +reason+ : malformed / expired / mismatch
      def self.construct_event(payload, sig_header, secret, tolerance: 300)
        timestamp, signatures = parse_signature_header(sig_header)
        if (Time.now.to_i - timestamp).abs > tolerance
          raise SanghoWebhookSignatureError.new(SanghoWebhookSignatureError::EXPIRED, 'Webhook timestamp too old.')
        end
        unless signature_valid?(payload, timestamp, signatures, secret)
          raise SanghoWebhookSignatureError.new(SanghoWebhookSignatureError::MISMATCH, 'Webhook signature mismatch.')
        end

        begin
          JSON.parse(payload, symbolize_names: true)
        rescue JSON::ParserError
          raise SanghoError.new('Webhook body is not valid JSON.', status_code: 400, raw: { code: 'invalid_payload' })
        end
      end

      # Génère un en-tête +Sangho-Signature+ valide pour tester votre endpoint webhook.
      def self.generate_test_header(payload, secret, timestamp: nil)
        ts = timestamp || Time.now.to_i
        "t=#{ts},v1=#{OpenSSL::HMAC.hexdigest('SHA256', secret, "#{ts}.#{payload}")}"
      end

      # @return [Array(Integer, Array<String>)] horodatage et signatures +v1+
      def self.parse_signature_header(sig_header)
        malformed = -> { SanghoWebhookSignatureError.new(SanghoWebhookSignatureError::MALFORMED, 'Invalid Sangho-Signature header.') }
        header = sig_header.to_s
        raise malformed.call if header.empty?

        timestamp = nil
        signatures = []
        header.split(',').each do |part|
          key, value = part.split('=', 2).map { |x| x.to_s.strip }
          next if value.nil?

          if key == 't'
            raise malformed.call unless value.match?(/\A\d+\z/)

            timestamp = value.to_i
          elsif key == 'v1' && !value.empty?
            signatures << value
          end
        end
        raise malformed.call if timestamp.nil? || signatures.empty?

        [timestamp, signatures]
      end

      def self.signature_valid?(payload, timestamp, signatures, secret)
        matched = false
        Array(secret).each do |candidate|
          next if candidate.to_s.empty?

          expected = OpenSSL::HMAC.hexdigest('SHA256', candidate.to_s, "#{timestamp}.#{payload}")
          # Pas de court-circuit : le temps ne dépend pas du +v1+ qui correspond.
          signatures.each do |received|
            same = expected.bytesize == received.bytesize && OpenSSL.fixed_length_secure_compare(expected, received)
            matched ||= same
          end
        end
        matched
      end
      private_class_method :parse_signature_header, :signature_valid?
    end
  end
end
