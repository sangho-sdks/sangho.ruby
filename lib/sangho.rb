# frozen_string_literal: true

require_relative 'sangho/version'
require_relative 'sangho/errors'
require_relative 'sangho/client'

# SDK Ruby de l'API Sangho.
module Sangho
  @api_key  = nil
  @base_url = 'https://api.sangho.ga/v1'
  @timeout  = 30

  class << self
    attr_accessor :api_key, :base_url, :timeout

    # Configuration en bloc :
    #   Sangho.configure { |c| c.api_key = "sk_test_xxx" }
    def configure
      yield self
    end

    # Raccourci : Sangho.new("sk_test_xxx")
    def new(api_key = self.api_key, base_url: @base_url, timeout: @timeout, **options)
      SanghoClient.new(api_key: api_key, base_url: base_url, timeout: timeout, **options)
    end
  end
end
