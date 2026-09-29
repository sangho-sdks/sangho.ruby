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

      # Vérifie la signature HMAC-SHA256 (en-tête « t=<timestamp>,v1=<signature> ») et retourne l'événement décodé.
      def self.construct_event(payload, sig_header, secret, tolerance: 300)
        parts = parse_signature_header(sig_header)
        validate_signature_header(parts, tolerance)
        validate_signature(payload, parts, secret)
        JSON.parse(payload, symbolize_names: true)
      end

      def self.parse_signature_header(sig_header)
        sig_header.to_s.split(',').each_with_object({}) do |part, hash|
          key, value = part.split('=', 2)
          hash[key] = value
        end
      end

      def self.validate_signature_header(parts, tolerance)
        timestamp = parts['t']
        unless timestamp && parts['v1']
          raise SanghoError.new('Invalid Sangho-Signature header.',
                                raw: { code: 'invalid_signature' })
        end
        return unless (Time.now.to_i - timestamp.to_i).abs > tolerance

        raise SanghoError.new('Webhook timestamp too old.', raw: { code: 'stale_event' })
      end

      def self.validate_signature(payload, parts, secret)
        expected = OpenSSL::HMAC.hexdigest('SHA256', secret, "#{parts['t']}.#{payload}")
        received = parts['v1'].to_s
        # Comparaison en temps constant (l'ancienne comparaison « == » fuyait la signature par mesure du temps de réponse).
        valid = expected.bytesize == received.bytesize && OpenSSL.fixed_length_secure_compare(expected, received)
        raise SanghoError.new('Webhook signature mismatch.', raw: { code: 'invalid_signature' }) unless valid
      end
      private_class_method :parse_signature_header, :validate_signature_header, :validate_signature
    end
  end
end
