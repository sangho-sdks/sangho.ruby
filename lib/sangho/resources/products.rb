# frozen_string_literal: true

module Sangho
  module Resources
    # client.products.{list, retrieve, create, update, delete, options}
    class Products < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('products.list')
        @http.get('/products/', criteria)
      end

      def retrieve(id)
        @http.assert_secret_key!('products.retrieve')
        @http.get("/products/#{id}/")
      end

      def create(name:, price:, **opts)
        @http.assert_secret_key!('products.create')
        @http.post('/products/', { name: name, price: price }.merge(opts))
      end

      def update(id, **payload)
        @http.assert_secret_key!('products.update')
        @http.patch("/products/#{id}/", payload)
      end

      def delete(id)
        @http.assert_secret_key!('products.delete')
        @http.delete("/products/#{id}/")
      end

      def options
        @http.options('/products/')
      end
    end
  end
end
