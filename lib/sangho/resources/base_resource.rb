# frozen_string_literal: true

module Sangho
  module Resources
    # Détient le client HTTP partagé.
    class BaseResource
      def initialize(http)
        @http = http
      end
    end
  end
end
