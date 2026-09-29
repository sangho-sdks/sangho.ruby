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

      # @param line_items [Array<Hash>] lignes du panier ; +product+ est facultatif, sinon +name+ et +unit_amount+
      #   (unité majeure) sont requis, ex. +[{ name: 'Robe', unit_amount: 5000, quantity: 1 }]+.
      # @param amount [Integer] ancienne signature (obsolète) : convertie en une ligne ad hoc.
      # @param connect [Hash] paiement avec répartition : +account+, +mode+, +commission+, +reserve_rate+,
      #   +external_reference+ (la réponse porte +connect_payment+).
      # @param idempotency_key [String] rejoue l'appel sans doublon.
      def create(success_url:, line_items: nil, amount: nil, cancel_url: nil, currency: 'XAF', **opts)
        @http.assert_secret_key!('checkout_sessions.create')
        if line_items.nil? && !amount.nil?
          warn '[DEPRECATION] checkout_sessions.create(amount:) est obsolète : passez line_items:.', uplevel: 1
          line_items = [{ name: 'Paiement', unit_amount: amount, quantity: 1 }]
        end
        raise ArgumentError, 'line_items is required' if line_items.nil?

        body = { line_items: line_items, success_url: success_url, currency: currency }.merge(opts)
        body[:cancel_url] = cancel_url if cancel_url
        @http.post('/checkout-sessions/', body)
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
