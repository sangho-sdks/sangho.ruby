# frozen_string_literal: true

module Sangho
  module Resources
    # client.sandbox.reset — purge les données de test de l'application (clients, produits, paiements, factures…).
    # L'application, ses clés et ses réglages sont conservés. Refusé côté backend avec une clé de production (sk_prod_*).
    class Sandbox < BaseResource
      def reset
        @http.assert_secret_key!('sandbox.reset')
        @http.post('/reset/')
      end
    end
  end
end
