# frozen_string_literal: true

require 'spec_helper'

# Idempotence : clé fournie par l’appelant, aucun rejeu d’un POST sans clé après une erreur réseau.
RSpec.describe 'idempotence' do
  let(:base) { 'https://api.sangho.ga/v1' }
  let(:json) { { 'Content-Type' => 'application/json' } }
  let(:client) { Sangho.new('sk_test_abc123456789', sleeper: ->(_) {}) }

  it 'transmet idempotency_key: de n’importe quelle méthode d’écriture, sans l’envoyer dans le corps' do
    req = stub_request(:post, "#{base}/customers/").to_return(status: 200, body: '{"id":"c"}', headers: json)
    client.customers.create(email: 'a@b.ga', name: 'A', idempotency_key: 'cust-1')
    expect(req.with(headers: { 'Idempotency-Key' => 'cust-1' }, body: { email: 'a@b.ga', name: 'A' }.to_json))
      .to have_been_requested
  end

  it 'génère une clé quand l’appelant n’en fournit pas' do
    req = stub_request(:post, "#{base}/customers/").to_return(status: 200, body: '{"id":"c"}', headers: json)
    client.customers.create(email: 'a@b.ga', name: 'A')
    expect(req.with { |r| r.headers['Idempotency-Key'].to_s.length > 20 }).to have_been_requested
  end

  it 'ne rejoue pas un POST sans clé après une erreur réseau' do
    stub_request(:post, "#{base}/customers/").to_timeout
    expect { client.customers.create(email: 'a@b.ga', name: 'A') }.to raise_error(Sangho::SanghoTimeoutError)
    expect(a_request(:post, "#{base}/customers/")).to have_been_made.once
  end

  it 'rejoue un POST avec clé fournie après une erreur réseau' do
    stub_request(:post, "#{base}/customers/").to_timeout.then.to_return(status: 200, body: '{"id":"c"}', headers: json)
    res = client.customers.create(email: 'a@b.ga', name: 'A', idempotency_key: 'cust-2')
    expect(res[:id]).to eq('c')
    expect(a_request(:post, "#{base}/customers/")).to have_been_made.twice
  end

  it 'checkout_sessions.create envoie line_items, currency et connect' do
    req = stub_request(:post, "#{base}/checkout-sessions/").to_return(status: 200, body: '{"id":"cs"}', headers: json)
    items = [{ name: 'Robe', unit_amount: 5000, quantity: 1 }]
    client.checkout_sessions.create(line_items: items, success_url: 'https://x/ok', connect: { account: 'acct_1' },
                                    idempotency_key: 'cs-1')
    expect(req.with(headers: { 'Idempotency-Key' => 'cs-1' }) do |r|
      body = JSON.parse(r.body)
      body['currency'] == 'XAF' && body['line_items'].size == 1 && body['connect']['account'] == 'acct_1'
    end).to have_been_requested
  end

  it 'checkout_sessions.create convertit l’ancien amount: en une ligne ad hoc (obsolète)' do
    req = stub_request(:post, "#{base}/checkout-sessions/").to_return(status: 200, body: '{"id":"cs"}', headers: json)
    expect { client.checkout_sessions.create(amount: 5000, success_url: 'https://x/ok') }.to output(/obsol/).to_stderr
    expect(req.with { |r| JSON.parse(r.body)['line_items'].first['unit_amount'] == 5000 }).to have_been_requested
  end

  it 'payment_intents.create envoie la devise et customer_email' do
    req = stub_request(:post, "#{base}/payment-intents/").to_return(status: 200, body: '{"id":"pi"}', headers: json)
    client.payment_intents.create(amount: 5000, customer_email: 'a@b.ga')
    expect(req.with(body: { amount: 5000, currency: 'XAF', customer_email: 'a@b.ga' }.to_json)).to have_been_requested
  end
end
