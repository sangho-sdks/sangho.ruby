# frozen_string_literal: true

module Sangho
  module Resources
    # client.payment_links.{list, retrieve, create, update, delete, archive, restore, options}
    class PaymentLinks < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('payment_links.list')
        @http.get('/payment-links/', criteria)
      end

      def retrieve(id)
        @http.assert_secret_key!('payment_links.retrieve')
        @http.get("/payment-links/#{id}/")
      end

      def create(amount:, **opts)
        @http.assert_secret_key!('payment_links.create')
        @http.post('/payment-links/', { amount: amount }.merge(opts))
      end

      def update(id, **payload)
        @http.assert_secret_key!('payment_links.update')
        @http.patch("/payment-links/#{id}/", payload)
      end

      # Pas de suppression physique côté API : DELETE archive le lien.
      def delete(id)
        @http.assert_secret_key!('payment_links.delete')
        @http.delete("/payment-links/#{id}/")
      end

      def archive(id)
        @http.assert_secret_key!('payment_links.archive')
        @http.post("/payment-links/#{id}/archive/")
      end

      def restore(id)
        @http.assert_secret_key!('payment_links.restore')
        @http.post("/payment-links/#{id}/restore/")
      end

      def options
        @http.options('/payment-links/')
      end
    end
  end
end
