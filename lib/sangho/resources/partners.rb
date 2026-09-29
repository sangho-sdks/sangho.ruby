# frozen_string_literal: true

module Sangho
  module Resources
    # client.partners.{list, retrieve, options} — ressource en lecture seule.
    class Partners < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('partners.list')
        @http.get('/partners/', criteria)
      end

      def retrieve(id)
        @http.assert_secret_key!('partners.retrieve')
        @http.get("/partners/#{id}/")
      end

      def options
        @http.options('/partners/')
      end
    end
  end
end
