# frozen_string_literal: true

module Sangho
  module Resources
    # client.security.{retrieve, update, add_allowed_ips, remove_allowed_ips, options}
    class Security < BaseResource
      def retrieve
        @http.assert_secret_key!('security.retrieve')
        @http.get('/security/me/')
      end

      def update(**payload)
        @http.assert_secret_key!('security.update')
        @http.patch('/security/update_me/', payload)
      end

      # Pas d'action dédiée côté backend pour ajouter/retirer des IP : on relit le profil, on recompose la liste
      # complète, puis on la renvoie via #update.
      def add_allowed_ips(ips)
        @http.assert_secret_key!('security.add_allowed_ips')
        current = Array(retrieve[:allowed_ips])
        update(allowed_ips: (current + Array(ips)).uniq)
      end

      def remove_allowed_ips(ips)
        @http.assert_secret_key!('security.remove_allowed_ips')
        current = Array(retrieve[:allowed_ips])
        update(allowed_ips: current - Array(ips))
      end

      def options
        @http.options('/security/')
      end
    end
  end
end
