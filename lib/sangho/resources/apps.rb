# frozen_string_literal: true

module Sangho
  module Resources
    # client.apps.{list, retrieve, create, update, delete, keys, options}
    class Apps < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('apps.list')
        @http.get('/apps/', criteria)
      end

      def retrieve(id)
        @http.assert_secret_key!('apps.retrieve')
        @http.get("/apps/#{id}/")
      end

      def create(name:, **opts)
        @http.assert_secret_key!('apps.create')
        @http.post('/apps/', { name: name }.merge(opts))
      end

      def update(id, **payload)
        @http.assert_secret_key!('apps.update')
        @http.patch("/apps/#{id}/", payload)
      end

      def delete(id)
        @http.assert_secret_key!('apps.delete')
        @http.delete("/apps/#{id}/")
      end

      # Paire de clés (publique / secrète) actuelle de l'application.
      def keys(id)
        @http.assert_secret_key!('apps.keys')
        @http.get("/apps/#{id}/keys/")
      end

      def options
        @http.options('/apps/')
      end
    end
  end
end
