# frozen_string_literal: true

module Sangho
  module Resources
    # client.payment_methods.{list, retrieve, attach, detach, set_default, options}
    # Les moyens de paiement sont créés par le paiement lui-même : l'API n'expose ni création, ni modification directe.
    class PaymentMethods < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('payment_methods.list')
        @http.get('/payment-methods/', criteria)
      end

      def retrieve(id)
        @http.assert_secret_key!('payment_methods.retrieve')
        @http.get("/payment-methods/#{id}/")
      end

      def set_default(id)
        @http.assert_secret_key!('payment_methods.set_default')
        @http.post("/payment-methods/#{id}/set-default/")
      end

      def attach(id, customer:)
        @http.assert_secret_key!('payment_methods.attach')
        @http.post("/payment-methods/#{id}/attach/", { customer: customer })
      end

      def detach(id)
        @http.assert_secret_key!('payment_methods.detach')
        @http.post("/payment-methods/#{id}/detach/")
      end

      def options
        @http.options('/payment-methods/')
      end
    end
  end
end
