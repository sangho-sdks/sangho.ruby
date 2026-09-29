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

      def create(amount:, customer:, **opts)
        @http.assert_secret_key!('payment_intents.create')
        @http.post('/payment-intents/', { amount: amount, customer: customer }.merge(opts))
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
