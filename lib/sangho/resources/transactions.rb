# frozen_string_literal: true

module Sangho
  module Resources
    # client.transactions.{list, retrieve, update, cancel, options}
    class Transactions < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('transactions.list')
        @http.get('/transactions/', criteria)
      end

      def retrieve(id)
        @http.assert_secret_key!('transactions.retrieve')
        @http.get("/transactions/#{id}/")
      end

      def update(id, **payload)
        @http.assert_secret_key!('transactions.update')
        @http.patch("/transactions/#{id}/", payload)
      end

      def cancel(id)
        @http.assert_secret_key!('transactions.cancel')
        @http.post("/transactions/#{id}/cancel/")
      end

      def options
        @http.options('/transactions/')
      end
    end
  end
end
