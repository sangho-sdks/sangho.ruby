# frozen_string_literal: true

module Sangho
  module Resources
    # client.receipts.{list, retrieve, get_pdf_url, options}
    class Receipts < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('receipts.list')
        @http.get('/receipts/', criteria)
      end

      def retrieve(id)
        @http.assert_secret_key!('receipts.retrieve')
        @http.get("/receipts/#{id}/")
      end

      # URL signée et expirante du PDF : { url:, expires_at: }
      def get_pdf_url(id)
        @http.assert_secret_key!('receipts.get_pdf_url')
        @http.get("/receipts/#{id}/pdf/")
      end

      def options
        @http.options('/receipts/')
      end
    end
  end
end
