# frozen_string_literal: true

module Sangho
  module Resources
    # client.customers.{list, retrieve, create, update, delete, list_payment_methods, options}
    class Customers < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('customers.list')
        @http.get('/customers/', criteria)
      end

      def retrieve(id)
        @http.assert_secret_key!('customers.retrieve')
        @http.get("/customers/#{id}/")
      end

      def create(email:, name:, **opts)
        @http.assert_secret_key!('customers.create')
        @http.post('/customers/', { email: email, name: name }.merge(opts))
      end

      def update(id, **payload)
        @http.assert_secret_key!('customers.update')
        @http.patch("/customers/#{id}/", payload)
      end

      def delete(id)
        @http.assert_secret_key!('customers.delete')
        @http.delete("/customers/#{id}/")
      end

      # Moyens de paiement d'un client : GET /payment-methods/?customer=<id>
      # (la route /customers/{id}/payment-methods/ n'existe pas côté API).
      def list_payment_methods(id, **criteria)
        @http.assert_secret_key!('customers.list_payment_methods')
        @http.get('/payment-methods/', criteria.merge(customer: id))
      end

      def options
        @http.options('/customers/')
      end
    end
  end
end
