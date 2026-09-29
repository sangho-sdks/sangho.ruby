# frozen_string_literal: true

module Sangho
  module Resources
    # client.payment_intents.{list, retrieve, create, update, confirm, capture, cancel, delete, options}
    class PaymentIntents < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('payment_intents.list')
        @http.get('/payment-intents/', criteria)
      end

      def retrieve(id)
        @http.assert_secret_key!('payment_intents.retrieve')
        @http.get("/payment-intents/#{id}/")
      end

      # @param amount [Integer, String] montant en unité MAJEURE de la devise (5000 = 5000 XAF), jamais en centimes.
      # @param currency [String] code ISO 4217 (défaut XAF) — exigé par le backend.
      # @param customer_email [String] e-mail de l'acheteur (le backend lit +customer_email+).
      # @param opts +idempotency_key:+, +customer:+ (transmis tel quel), +description+, +metadata+…
      def create(amount:, currency: 'XAF', customer_email: nil, **opts)
        @http.assert_secret_key!('payment_intents.create')
        body = { amount: amount, currency: currency }.merge(opts)
        body[:customer_email] = customer_email if customer_email
        @http.post('/payment-intents/', body)
      end

      def update(id, **payload)
        @http.assert_secret_key!('payment_intents.update')
        @http.patch("/payment-intents/#{id}/", payload)
      end

      def confirm(id, **payload)
        @http.assert_secret_key!('payment_intents.confirm')
        @http.post("/payment-intents/#{id}/confirm/", payload)
      end

      def capture(id, **payload)
        @http.assert_secret_key!('payment_intents.capture')
        @http.post("/payment-intents/#{id}/capture/", payload)
      end

      def cancel(id, **payload)
        @http.assert_secret_key!('payment_intents.cancel')
        @http.post("/payment-intents/#{id}/cancel/", payload)
      end

      # DELETE est un alias de cancel côté API (comme Stripe : on annule, on ne supprime pas).
      def delete(id)
        @http.assert_secret_key!('payment_intents.delete')
        @http.delete("/payment-intents/#{id}/")
      end

      def options
        @http.options('/payment-intents/')
      end
    end
  end
end
