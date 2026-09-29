# frozen_string_literal: true

module Sangho
  module Resources
    # client.addresses.{list, retrieve, create, update, delete, options}
    class Addresses < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('addresses.list')
        @http.get('/addresses/', criteria)
      end

      def retrieve(id)
        @http.assert_secret_key!('addresses.retrieve')
        @http.get("/addresses/#{id}/")
      end

      def create(**payload)
        @http.assert_secret_key!('addresses.create')
        @http.post('/addresses/', payload)
      end

      def update(id, **payload)
        @http.assert_secret_key!('addresses.update')
        @http.patch("/addresses/#{id}/", payload)
      end

      def delete(id)
        @http.assert_secret_key!('addresses.delete')
        @http.delete("/addresses/#{id}/")
      end

      def options
        @http.options('/addresses/')
      end
    end
  end
end
