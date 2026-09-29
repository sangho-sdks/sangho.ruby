# frozen_string_literal: true

module Sangho
  module Resources
    # client.terminal.readers.*  — lecteurs de carte physiques
    # client.terminal.sessions.* — sessions de paiement en personne
    # client.terminal.offline.*  — synchronisation des transactions hors ligne
    class Terminal < BaseResource
      attr_reader :readers, :sessions, :offline

      def initialize(http)
        super
        @readers = Readers.new(http)
        @sessions = Sessions.new(http)
        @offline = Offline.new(http)
      end

      # Lecteurs de carte.
      class Readers < BaseResource
        def list(**criteria)
          @http.assert_secret_key!('terminal.readers.list')
          @http.get('/terminal/readers/', criteria)
        end

        def retrieve(id)
          @http.assert_secret_key!('terminal.readers.retrieve')
          @http.get("/terminal/readers/#{id}/")
        end

        def create(**payload)
          @http.assert_secret_key!('terminal.readers.create')
          @http.post('/terminal/readers/', payload)
        end

        def update(id, **payload)
          @http.assert_secret_key!('terminal.readers.update')
          @http.patch("/terminal/readers/#{id}/", payload)
        end

        # Désactive le lecteur (suppression logique).
        def disable(id)
          @http.assert_secret_key!('terminal.readers.disable')
          @http.delete("/terminal/readers/#{id}/")
        end

        def refresh_token(id)
          @http.assert_secret_key!('terminal.readers.refresh_token')
          @http.post("/terminal/readers/#{id}/refresh-token/")
        end

        def heartbeat(id)
          @http.assert_secret_key!('terminal.readers.heartbeat')
          @http.post("/terminal/readers/#{id}/heartbeat/")
        end

        def options
          @http.options('/terminal/readers/')
        end
      end

      # Sessions de paiement.
      class Sessions < BaseResource
        def list(**criteria)
          @http.assert_secret_key!('terminal.sessions.list')
          @http.get('/terminal/sessions/', criteria)
        end

        def retrieve(id)
          @http.assert_secret_key!('terminal.sessions.retrieve')
          @http.get("/terminal/sessions/#{id}/")
        end

        def create(**payload)
          @http.assert_secret_key!('terminal.sessions.create')
          @http.post('/terminal/sessions/', payload)
        end

        def present_payment_method(id, **payload)
          @http.assert_secret_key!('terminal.sessions.present_payment_method')
          @http.post("/terminal/sessions/#{id}/present-payment-method/", payload)
        end

        def poll_status(id)
          @http.assert_secret_key!('terminal.sessions.poll_status')
          @http.get("/terminal/sessions/#{id}/status/")
        end

        def cancel(id)
          @http.assert_secret_key!('terminal.sessions.cancel')
          @http.post("/terminal/sessions/#{id}/cancel/")
        end

        def options
          @http.options('/terminal/sessions/')
        end
      end

      # Transactions hors ligne.
      class Offline < BaseResource
        def sync(**payload)
          @http.assert_secret_key!('terminal.offline.sync')
          @http.post('/terminal/offline/sync/', payload)
        end

        def list(**criteria)
          @http.assert_secret_key!('terminal.offline.list')
          @http.get('/terminal/offline/sync/', criteria)
        end

        def options
          @http.options('/terminal/offline/sync/')
        end
      end
    end
  end
end
