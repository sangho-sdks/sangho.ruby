# frozen_string_literal: true

module Sangho
  module Resources
    # client.refunds.{list, retrieve, create, cancel, options}
    class Refunds < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('refunds.list')
        @http.get('/refunds/', criteria)
      end

      def retrieve(id)
        @http.assert_secret_key!('refunds.retrieve')
        @http.get("/refunds/#{id}/")
      end

      def create(transaction:, **opts)
        @http.assert_secret_key!('refunds.create')
        @http.post('/refunds/', { transaction: transaction }.merge(opts))
      end

      def cancel(id)
        @http.assert_secret_key!('refunds.cancel')
        @http.post("/refunds/#{id}/cancel/")
      end

      def options
        @http.options('/refunds/')
      end
    end
  end
end
