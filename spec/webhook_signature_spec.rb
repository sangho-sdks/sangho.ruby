# frozen_string_literal: true

require 'spec_helper'

# Signature des webhooks : erreurs typées, rotation, tolérance, corps brut.
RSpec.describe 'signature des webhooks' do
  let(:secret) { 'whsec_test_secret' }
  let(:body) do
    { id: 'evt_1', type: 'kyc.updated', created: 1_780_000_100,
      data: { object: { id: "acct_#{'b' * 32}", status: 'active', charges_enabled: true } } }.to_json
  end

  def sign(key, stamp, payload)
    OpenSSL::HMAC.hexdigest('SHA256', key, "#{stamp}.#{payload}")
  end

  def failure(header, payload: body, key: secret, tolerance: 300)
    Sangho::Resources::Webhooks.construct_event(payload, header, key, tolerance: tolerance)
    raise 'SanghoWebhookSignatureError attendue'
  rescue Sangho::SanghoWebhookSignatureError => e
    e
  end

  it 'retourne l’événement quand la signature est valide' do
    ts = Time.now.to_i
    event = Sangho::Resources::Webhooks.construct_event(body, "t=#{ts},v1=#{sign(secret, ts, body)}", secret)
    expect(event[:type]).to eq('kyc.updated')
    expect(event[:data][:object][:charges_enabled]).to be(true)
  end

  it 'generate_test_header produit un en-tête que construct_event accepte' do
    header = Sangho::Resources::Webhooks.generate_test_header(body, secret)
    expect(Sangho::Resources::Webhooks.construct_event(body, header, secret)[:type]).to eq('kyc.updated')
    expect(Sangho::Resources::Webhooks.generate_test_header('x', secret, timestamp: 1_780_000_000))
      .to match(/\At=1780000000,v1=[0-9a-f]{64}\z/)
  end

  it 'accepte un corps UTF-8' do
    payload = { type: 'account.updated', data: { object: { business_name: 'Café Épicé' } } }.to_json
    header = Sangho::Resources::Webhooks.generate_test_header(payload, secret)
    expect(Sangho::Resources::Webhooks.construct_event(payload, header, secret)[:type]).to eq('account.updated')
  end

  it 'corps altéré -> mismatch (401)' do
    ts = Time.now.to_i
    e = failure("t=#{ts},v1=#{sign(secret, ts, body)}", payload: "#{body} ")
    expect(e.reason).to eq('mismatch')
    expect(e.status_code).to eq(401)
    expect(e.code).to eq('invalid_signature')
  end

  it 'mauvais secret -> mismatch' do
    ts = Time.now.to_i
    expect(failure("t=#{ts},v1=#{sign('autre', ts, body)}").reason).to eq('mismatch')
  end

  it 'horodatage trop ancien ou dans le futur -> expired (400)' do
    [Time.now.to_i - 3600, Time.now.to_i + 3600].each do |ts|
      e = failure("t=#{ts},v1=#{sign(secret, ts, body)}")
      expect(e.reason).to eq('expired')
      expect(e.status_code).to eq(400)
      expect(e.code).to eq('stale_event')
    end
  end

  it 'respecte la tolérance fournie' do
    ts = Time.now.to_i - 3600
    header = "t=#{ts},v1=#{sign(secret, ts, body)}"
    expect(Sangho::Resources::Webhooks.construct_event(body, header, secret, tolerance: 7200)[:id]).to eq('evt_1')
  end

  it 'en-têtes illisibles -> malformed (400)' do
    ['', 'n’importe quoi', 't=abc,v1=deadbeef', "t=#{Time.now.to_i}", 'v1=deadbeef'].each do |header|
      e = failure(header)
      expect(e.reason).to eq('malformed')
      expect(e.status_code).to eq(400)
    end
  end

  it 'accepte plusieurs v1 (rotation) et plusieurs secrets' do
    ts = Time.now.to_i
    header = "t=#{ts},v1=#{sign('ancien', ts, body)},v1=#{sign(secret, ts, body)}"
    expect(Sangho::Resources::Webhooks.construct_event(body, header, secret)[:id]).to eq('evt_1')
    header = "t=#{ts},v1=#{sign('nouveau', ts, body)}"
    expect(Sangho::Resources::Webhooks.construct_event(body, header, [secret, 'nouveau'])[:id]).to eq('evt_1')
  end

  it 'corps signé mais non JSON -> SanghoError explicite' do
    payload = 'pas du json'
    header = Sangho::Resources::Webhooks.generate_test_header(payload, secret)
    expect { Sangho::Resources::Webhooks.construct_event(payload, header, secret) }
      .to raise_error(Sangho::SanghoError, /not valid JSON/)
  end

  it 'reste une SanghoError (compatibilité des anciens rescue)' do
    expect(Sangho::SanghoWebhookSignatureError.ancestors).to include(Sangho::SanghoError)
  end
end
