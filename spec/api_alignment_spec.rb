# frozen_string_literal: true

require 'spec_helper'

# Alignement sur l'API Sangho réelle (backend/api) : chaque route testée existe côté backend ; les méthodes retirées
# appelaient des routes inexistantes (404/405) et ne doivent pas revenir.
RSpec.describe 'alignement sur l’API' do
  let(:base) { 'https://api.sangho.ga/v1' }
  let(:client) { Sangho.new('sk_test_abc123456789') }
  let(:json) { { 'Content-Type' => 'application/json' } }

  def ok(verb, path, body = { id: 'x' })
    stub_request(verb, "#{base}#{path}").to_return(status: 200, body: body.to_json, headers: json)
  end

  {
    'account.retrieve' => [:get, '/account/', ->(c) { c.account.retrieve }],
    'addresses.list' => [:get, '/addresses/', ->(c) { c.addresses.list }],
    'addresses.create' => [:post, '/addresses/', ->(c) { c.addresses.create(line1: 'x') }],
    'apps.keys' => [:get, '/apps/app_1/keys/', ->(c) { c.apps.keys('app_1') }],
    'invoices.get_pdf_url' => [:get, '/invoices/inv_1/pdf/', ->(c) { c.invoices.get_pdf_url('inv_1') }],
    'receipts.get_pdf_url' => [:get, '/receipts/rcp_1/pdf/', ->(c) { c.receipts.get_pdf_url('rcp_1') }],
    'payment_intents.delete' => [:delete, '/payment-intents/pi_1/', ->(c) { c.payment_intents.delete('pi_1') }],
    'payment_links.archive' => [:post, '/payment-links/pl_1/archive/', ->(c) { c.payment_links.archive('pl_1') }],
    'payment_links.restore' => [:post, '/payment-links/pl_1/restore/', ->(c) { c.payment_links.restore('pl_1') }],
    'payment_methods.attach' => [:post, '/payment-methods/pm_1/attach/', lambda { |c|
      c.payment_methods.attach('pm_1', customer: 'c')
    }],
    'payment_methods.set_default' => [:post, '/payment-methods/pm_1/set-default/', lambda { |c|
      c.payment_methods.set_default('pm_1')
    }],
    'sandbox.reset' => [:post, '/reset/', ->(c) { c.sandbox.reset }],
    'security.retrieve' => [:get, '/security/me/', ->(c) { c.security.retrieve }],
    'security.update' => [:patch, '/security/update_me/', ->(c) { c.security.update(allowed_ips: []) }],
    'subscriptions.reactivate' => [:post, '/subscriptions/sub_1/reactivate/', ->(c) { c.subscriptions.reactivate('sub_1') }],
    'transactions.cancel' => [:post, '/transactions/tx_1/cancel/', ->(c) { c.transactions.cancel('tx_1') }],
    'webhooks.enable' => [:post, '/webhooks/wh_1/enable/', ->(c) { c.webhooks.enable('wh_1') }],
    'webhooks.disable' => [:post, '/webhooks/wh_1/disable/', ->(c) { c.webhooks.disable('wh_1') }],
    'webhooks.retrieve_delivery' => [:get, '/webhooks/wh_1/deliveries/d_1/', lambda { |c|
      c.webhooks.retrieve_delivery('wh_1', 'd_1')
    }],
    'terminal.readers.heartbeat' => [:post, '/terminal/readers/r_1/heartbeat/', ->(c) { c.terminal.readers.heartbeat('r_1') }],
    'terminal.readers.refresh_token' => [:post, '/terminal/readers/r_1/refresh-token/', lambda { |c|
      c.terminal.readers.refresh_token('r_1')
    }],
    'terminal.sessions.poll_status' => [:get, '/terminal/sessions/s_1/status/', ->(c) { c.terminal.sessions.poll_status('s_1') }],
    'terminal.sessions.present_payment_method' => [:post, '/terminal/sessions/s_1/present-payment-method/',
                                                   ->(c) { c.terminal.sessions.present_payment_method('s_1', card: 'x') }],
    'terminal.offline.sync' => [:post, '/terminal/offline/sync/', ->(c) { c.terminal.offline.sync(transactions: []) }]
  }.each do |name, (verb, path, call)|
    it "#{name} appelle #{verb.upcase} #{path}" do
      stub = ok(verb, path)
      call.call(client)
      expect(stub).to have_been_requested
    end
  end

  it 'filtre les moyens de paiement d’un client par ?customer=' do
    stub = stub_request(:get, "#{base}/payment-methods/").with(query: { customer: 'cus_1' })
                                                         .to_return(status: 200, body: '{"data":[]}', headers: json)
    client.customers.list_payment_methods('cus_1')
    expect(stub).to have_been_requested
  end

  it 'autorise checkout_sessions.retrieve avec une clé publique' do
    ok(:get, '/checkout-sessions/cs_1/')
    expect { Sangho.new('pk_test_abc123456789').checkout_sessions.retrieve('cs_1') }.not_to raise_error
  end

  it 'refuse les autres méthodes avec une clé publique' do
    expect { Sangho.new('pk_test_abc123456789').webhooks.list }.to raise_error(Sangho::SanghoPublicKeyError)
  end

  {
    'apps.roll_secret' => %i[apps roll_secret], 'customers.list_transactions' => %i[customers list_transactions],
    'invoices.finalize' => %i[invoices finalize], 'partners.create' => %i[partners create],
    'partners.update' => %i[partners update], 'partners.delete' => %i[partners delete],
    'payment_links.deactivate' => %i[payment_links deactivate], 'payment_methods.create' => %i[payment_methods create],
    'payment_methods.update' => %i[payment_methods update], 'payment_methods.delete' => %i[payment_methods delete],
    'products.archive' => %i[products archive], 'products.restore' => %i[products restore],
    'refunds.update' => %i[refunds update], 'security.roll_secret_key' => %i[security roll_secret_key],
    'security.list_sessions' => %i[security list_sessions], 'security.revoke_session' => %i[security revoke_session]
  }.each do |name, (resource, method)|
    it "#{name} n’existe plus (route inexistante côté API)" do
      expect(client.public_send(resource)).not_to respond_to(method)
    end
  end

  describe Sangho::Resources::Webhooks do
    let(:secret) { 'whsec_test' }
    let(:payload) { '{"type":"payment_intent.succeeded"}' }

    def header(payload, secret, timestamp = Time.now.to_i)
      "t=#{timestamp},v1=#{OpenSSL::HMAC.hexdigest('SHA256', secret, "#{timestamp}.#{payload}")}"
    end

    it 'accepte une signature valide' do
      event = described_class.construct_event(payload, header(payload, secret), secret)
      expect(event[:type]).to eq('payment_intent.succeeded')
    end

    it 'refuse une signature falsifiée, un événement périmé et un en-tête invalide' do
      expect do
        described_class.construct_event(payload, header(payload, 'autre'), secret)
      end.to raise_error(Sangho::SanghoError, /mismatch/)
      expect { described_class.construct_event(payload, header(payload, secret, Time.now.to_i - 4000), secret) }
        .to raise_error(Sangho::SanghoError, /too old/)
      expect { described_class.construct_event(payload, 'garbage', secret) }.to raise_error(Sangho::SanghoError, /Invalid/)
    end
  end
end
