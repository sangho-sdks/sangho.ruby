# frozen_string_literal: true

module Sangho
  module Resources
    # client.checkout_sessions.{list, retrieve, create, expire, delete, options}
    class CheckoutSessions < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('checkout_sessions.list')
        @http.get('/checkout-sessions/', criteria)
      end

      # Le backend autorise explicitement la clé publique sur cette action (page de confirmation côté navigateur).
      def retrieve(id)
        @http.get("/checkout-sessions/#{id}/")
      end

      def create(amount:, success_url:, cancel_url:, **opts)
        @http.assert_secret_key!('checkout_sessions.create')
        @http.post('/checkout-sessions/', { amount: amount, success_url: success_url, cancel_url: cancel_url }.merge(opts))
      end

      def expire(id)
        @http.assert_secret_key!('checkout_sessions.expire')
        @http.post("/checkout-sessions/#{id}/expire/")
      end

      def delete(id)
        @http.assert_secret_key!('checkout_sessions.delete')
        @http.delete("/checkout-sessions/#{id}/")
      end

      def options
        @http.options('/checkout-sessions/')
      end
    end
  end
end
