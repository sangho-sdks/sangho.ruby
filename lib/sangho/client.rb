# frozen_string_literal: true

require_relative 'http_client'
require_relative 'resources/base_resource'
%w[account addresses apps checkout_sessions connect customers invoices partners payment_intents payment_links
   payment_methods products receipts refunds sandbox security subscriptions terminal transactions webhooks].each do |name|
  require_relative "resources/#{name}"
end

module Sangho
  # Point d'entrée de l'API : un accesseur par ressource (client.customers, client.terminal.readers…).
  class SanghoClient
    RESOURCE_CLASSES = {
      account: Resources::Account,
      addresses: Resources::Addresses,
      apps: Resources::Apps,
      checkout_sessions: Resources::CheckoutSessions,
      connect: Resources::Connect,
      customers: Resources::Customers,
      invoices: Resources::Invoices,
      partners: Resources::Partners,
      payment_intents: Resources::PaymentIntents,
      payment_links: Resources::PaymentLinks,
      payment_methods: Resources::PaymentMethods,
      products: Resources::Products,
      receipts: Resources::Receipts,
      refunds: Resources::Refunds,
      sandbox: Resources::Sandbox,
      security: Resources::Security,
      subscriptions: Resources::Subscriptions,
      terminal: Resources::Terminal,
      transactions: Resources::Transactions,
      webhooks: Resources::Webhooks
    }.freeze

    attr_reader(*RESOURCE_CLASSES.keys)

    # @param max_retries [Integer] nouvelles tentatives sur 429, 5xx et erreurs réseau (backoff exponentiel).
    def initialize(api_key: Sangho.api_key, base_url: Sangho.base_url, timeout: Sangho.timeout, **options)
      raise ArgumentError, 'api_key is required' unless api_key

      http = HttpClient.new(api_key: api_key, base_url: base_url, timeout: timeout, **options)
      RESOURCE_CLASSES.each { |key, klass| instance_variable_set("@#{key}", klass.new(http)) }
    end
  end
end
