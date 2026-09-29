# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sangho::HttpClient do
  let(:base) { 'https://api.sangho.ga/v1' }
  let(:sleeps) { [] }
  let(:client) do
    Sangho.new('sk_test_abc123456789', max_retries: 2, sleeper: ->(seconds) { sleeps << seconds })
  end
  let(:json) { { 'Content-Type' => 'application/json' } }

  def stub_status(status, body = {}, headers = json)
    stub_request(:get, "#{base}/customers/").to_return(status: status, body: body.to_json, headers: headers)
  end

  describe 'clés API' do
    it 'accepte les clés de production sk_prod_ / pk_prod_ (et non pk_live_)' do
      expect { Sangho.new('sk_prod_abc123456789xyz') }.not_to raise_error
      expect { Sangho.new('sk_live_abc123456789xyz') }.to raise_error(ArgumentError, /Invalid API key format/)
    end

    it 'refuse une base non HTTPS (sauf localhost)' do
      expect do
        Sangho.new('sk_test_abc123456789', base_url: 'http://api.sangho.ga/v1')
      end.to raise_error(ArgumentError, /non-HTTPS/)
      expect { Sangho.new('sk_test_abc123456789', base_url: 'http://localhost:8000/v1') }.not_to raise_error
    end

    it 'cible api.sangho.ga par défaut et envoie la version du SDK' do
      stub = stub_request(:get, "#{base}/customers/")
             .with(headers: { 'X-Sangho-SDK' => "ruby/#{Sangho::VERSION}", 'X-Sangho-Environment' => 'sandbox' })
             .to_return(status: 200, body: '{}', headers: json)
      client.customers.list
      expect(stub).to have_been_requested
    end
  end

  describe 'erreurs typées (miroir du SDK JS)' do
    it 'expose type + code métier + request_id du backend' do
      stub_status(422, { type: 'VALIDATION_ERROR', code: 'AMOUNT_TOO_SMALL', message: 'Trop petit', param: 'amount',
                         errors: { amount: ['min 100'] }, request_id: 'req_1',
                         doc_url: 'https://docs.sangho.ga/errors#AMOUNT_TOO_SMALL' })
      expect { client.customers.list }.to raise_error(Sangho::SanghoValidationError) { |e|
        expect(e.type).to eq('VALIDATION_ERROR')
        expect(e.code).to eq('AMOUNT_TOO_SMALL')
        expect(e.param).to eq('amount')
        expect(e.request_id).to eq('req_1')
        expect(e.field_errors).to eq({ amount: ['min 100'] })
        expect(e.message).to eq('amount: min 100')
      }
    end

    it 'retombe sur le type quand le backend ne donne pas de code' do
      stub_status(404, { message: 'Introuvable' })
      expect { client.customers.list }.to raise_error(Sangho::SanghoNotFoundError) { |e|
        expect(e.type).to eq('NOT_FOUND_ERROR')
        expect(e.code).to eq('NOT_FOUND_ERROR')
        expect(e.status_code).to eq(404)
      }
    end

    it 'distingue clé publique refusée (casse ignorée) et permission' do
      stub_status(403, { code: 'PUBLIC_KEY_NOT_ALLOWED', message: 'no' })
      expect { client.customers.list }.to raise_error(Sangho::SanghoPublicKeyError)
      WebMock.reset!
      stub_status(403, { code: 'PERMISSION_DENIED', message: 'no' })
      expect { client.customers.list }.to raise_error(Sangho::SanghoPermissionError)
    end

    it 'mappe 401 et 409' do
      stub_status(401, { message: 'x' })
      expect { client.customers.list }.to raise_error(Sangho::SanghoAuthError)
      WebMock.reset!
      stub_status(409, { code: 'IDEMPOTENCY_CONFLICT' })
      expect { client.customers.list }.to raise_error(Sangho::SanghoIdempotencyError) { |e| expect(e.type).to eq('CONFLICT_ERROR') }
    end
  end

  describe 'retry' do
    it 'réessaie un 503 avec backoff exponentiel puis réussit' do
      stub_request(:get, "#{base}/customers/").to_return({ status: 503, body: '{}' },
                                                         { status: 200, body: '{"data":[]}', headers: json })
      expect(client.customers.list).to eq({ data: [] })
      expect(sleeps).to eq([0.5])
    end

    it 'respecte retry_after (et non retry_later) sur un 429' do
      stub_request(:get, "#{base}/customers/").to_return({ status: 429, body: { retry_after: 7 }.to_json, headers: json },
                                                         { status: 200, body: '{}', headers: json })
      client.customers.list
      expect(sleeps).to eq([7])
    end

    it 'lit l’en-tête Retry-After quand le corps n’a pas retry_after' do
      stub_status(429, {}, json.merge('Retry-After' => '3'))
      expect { client.customers.list }.to raise_error(Sangho::SanghoRateLimitError) { |e| expect(e.retry_after).to eq(3) }
    end

    it 'abandonne après max_retries et lève l’erreur' do
      stub_status(500, { message: 'boom' })
      expect { client.customers.list }.to raise_error(Sangho::SanghoError) { |e| expect(e.status_code).to eq(500) }
      expect(sleeps.length).to eq(2)
    end

    it 'ne réessaie jamais un 4xx permanent' do
      stub = stub_status(404, { message: 'nope' })
      expect { client.customers.list }.to raise_error(Sangho::SanghoNotFoundError)
      expect(stub).to have_been_requested.once
      expect(sleeps).to be_empty
    end
  end

  describe 'erreurs réseau' do
    it 'convertit un délai dépassé en SanghoTimeoutError après les essais' do
      stub_request(:get, "#{base}/customers/").to_timeout
      expect { client.customers.list }.to raise_error(Sangho::SanghoTimeoutError) { |e| expect(e.type).to eq('TIMEOUT_ERROR') }
      expect(sleeps.length).to eq(2)
    end

    it 'convertit une connexion refusée en SanghoNetworkError' do
      stub_request(:get, "#{base}/customers/").to_raise(Faraday::ConnectionFailed.new('refused'))
      expect { client.customers.list }.to raise_error(Sangho::SanghoNetworkError) { |e| expect(e.code).to eq('NETWORK_ERROR') }
    end
  end

  describe 'idempotence' do
    it 'envoie une Idempotency-Key sur chaque POST' do
      stub = stub_request(:post, "#{base}/customers/").with { |req| req.headers['Idempotency-Key'].to_s.length == 36 }
                                                      .to_return(status: 201, body: '{}', headers: json)
      client.customers.create(email: 'a@b.c', name: 'A')
      expect(stub).to have_been_requested
    end
  end
end
