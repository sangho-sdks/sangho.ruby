# frozen_string_literal: true

module Sangho
  module Resources
    # client.subscriptions.{list, retrieve, create, update, cancel, reactivate, pause, resume, options}
    class Subscriptions < BaseResource
      def list(**criteria)
        @http.assert_secret_key!('subscriptions.list')
        @http.get('/subscriptions/', criteria)
      end

      def retrieve(id)
        @http.assert_secret_key!('subscriptions.retrieve')
        @http.get("/subscriptions/#{id}/")
      end

      def create(customer:, plan:, **opts)
        @http.assert_secret_key!('subscriptions.create')
        @http.post('/subscriptions/', { customer: customer, plan: plan }.merge(opts))
      end

      def update(id, **payload)
        @http.assert_secret_key!('subscriptions.update')
        @http.patch("/subscriptions/#{id}/", payload)
      end

      def cancel(id, **opts)
        @http.assert_secret_key!('subscriptions.cancel')
        @http.post("/subscriptions/#{id}/cancel/", opts)
      end

      def reactivate(id)
        @http.assert_secret_key!('subscriptions.reactivate')
        @http.post("/subscriptions/#{id}/reactivate/")
      end

      def pause(id)
        @http.assert_secret_key!('subscriptions.pause')
        @http.post("/subscriptions/#{id}/pause/")
      end

      def resume(id)
        @http.assert_secret_key!('subscriptions.resume')
        @http.post("/subscriptions/#{id}/resume/")
      end

      def options
        @http.options('/subscriptions/')
      end
    end
  end
end
