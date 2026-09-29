# frozen_string_literal: true

module Sangho
  module Resources
    # client.invoices.{list, retrieve, create, update, delete, pay, void, mark_uncollectible, send_invoice, get_pdf_url}
    class Invoices < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('invoices.list')
        @http.get('/invoices/', criteria)
      end

      def retrieve(id)
        @http.assert_secret_key!('invoices.retrieve')
        @http.get("/invoices/#{id}/")
      end

      def create(customer:, **opts)
        @http.assert_secret_key!('invoices.create')
        @http.post('/invoices/', { customer: customer }.merge(opts))
      end

      def update(id, **payload)
        @http.assert_secret_key!('invoices.update')
        @http.patch("/invoices/#{id}/", payload)
      end

      def delete(id)
        @http.assert_secret_key!('invoices.delete')
        @http.delete("/invoices/#{id}/")
      end

      def pay(id, **payload)
        @http.assert_secret_key!('invoices.pay')
        @http.post("/invoices/#{id}/pay/", payload)
      end

      def void(id)
        @http.assert_secret_key!('invoices.void')
        @http.post("/invoices/#{id}/void/")
      end

      def mark_uncollectible(id)
        @http.assert_secret_key!('invoices.mark_uncollectible')
        @http.post("/invoices/#{id}/mark-uncollectible/")
      end

      def send_invoice(id)
        @http.assert_secret_key!('invoices.send_invoice')
        @http.post("/invoices/#{id}/send/")
      end

      # URL signée et expirante du PDF : { url:, expires_at: }
      def get_pdf_url(id)
        @http.assert_secret_key!('invoices.get_pdf_url')
        @http.get("/invoices/#{id}/pdf/")
      end

      def options
        @http.options('/invoices/')
      end
    end
  end
end
