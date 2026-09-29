# frozen_string_literal: true

module Sangho
  module Resources
    # client.account.retrieve — l'application liée à la clé secrète utilisée (introspection « qui suis-je »).
    class Account < BaseResource
      def retrieve
        @http.assert_secret_key!('account.retrieve')
        @http.get('/account/')
      end
    end
  end
end
