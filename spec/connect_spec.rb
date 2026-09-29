# frozen_string_literal: true

require 'spec_helper'

# Paiements Connect (séquestre) : comptes, KYC, soldes, retraits, release / refund / freeze, sans réseau.
RSpec.describe 'Connect' do
  let(:base) { 'https://api.sangho.ga/v1' }
  let(:client) { Sangho.new('sk_test_abc123456789') }
  let(:json) { { 'Content-Type' => 'application/json' } }
  let(:acct) { "acct_#{'a' * 32}" }
  let(:pay) { "cpay_#{'b' * 32}" }

  def stub(verb, path, body = { id: 'x' }, status: 200)
    stub_request(verb, "#{base}#{path}").to_return(status: status, body: body.to_json, headers: json)
  end

  describe 'comptes' do
    it 'create envoie external_id et email, et la clé d’idempotence fournie' do
      req = stub(:post, '/connect/accounts/', { id: acct, claim_token: 'ct_1' })
      res = client.connect.accounts.create(external_id: 'seller-1', email: 'a@b.ga', idempotency_key: 'acct-seller-1')
      expect(res[:claim_token]).to eq('ct_1')
      expect(req.with(headers: { 'Idempotency-Key' => 'acct-seller-1' },
                      body: { external_id: 'seller-1', email: 'a@b.ga' }.to_json)).to have_been_requested
    end

    it 'retrieve, list, balance, list_payouts et reissue_claim_token appellent les bonnes routes' do
      stub(:get, "/connect/accounts/#{acct}/")
      stub(:get, '/connect/accounts/', { object: 'list', data: [] })
      stub(:get, "/connect/accounts/#{acct}/balance/")
      stub(:get, "/connect/accounts/#{acct}/payouts/", { object: 'list', data: [] })
      stub(:post, "/connect/accounts/#{acct}/claim-token/", { id: acct, claim_token: 'ct_2' })
      client.connect.accounts.retrieve(acct)
      client.connect.accounts.list
      client.connect.accounts.balance(acct)
      client.connect.accounts.list_payouts(acct)
      expect(client.connect.accounts.reissue_claim_token(acct)[:claim_token]).to eq('ct_2')
    end

    it 'create_kyc_session envoie return_url et refresh_url' do
      req = stub(:post, "/connect/accounts/#{acct}/kyc-session/", { url: 'https://kyc', account: acct })
      client.connect.accounts.create_kyc_session(acct, return_url: 'https://x/ok', refresh_url: 'https://x/retry')
      expect(req.with(body: { return_url: 'https://x/ok', refresh_url: 'https://x/retry' }.to_json)).to have_been_requested
    end

    it 'create_payout exige une clé d’idempotence et n’appelle pas le réseau sans elle' do
      expect { client.connect.accounts.create_payout(acct, amount: 1000, destination: 'pm_1', idempotency_key: '') }
        .to raise_error(Sangho::SanghoValidationError, /idempotence/)
      expect(a_request(:any, /sangho/)).not_to have_been_made
    end

    it 'create_payout envoie montant, destination et clé' do
      req = stub(:post, "/connect/accounts/#{acct}/payouts/", { id: 'po_1' })
      client.connect.accounts.create_payout(acct, amount: '1000', destination: 'pm_1', idempotency_key: 'payout-1')
      expect(req.with(headers: { 'Idempotency-Key' => 'payout-1' },
                      body: { amount: '1000', destination: 'pm_1' }.to_json)).to have_been_requested
    end
  end

  describe 'paiements' do
    it 'release envoie la clé d’idempotence et exige qu’elle existe' do
      req = stub(:post, "/connect/payments/#{pay}/release/", { status: 'released' })
      client.connect.payments.release(pay, idempotency_key: 'release-ORDER-1')
      expect(req.with(headers: { 'Idempotency-Key' => 'release-ORDER-1' })).to have_been_requested
      expect { client.connect.payments.release(pay, idempotency_key: nil) }.to raise_error(Sangho::SanghoValidationError)
    end

    it 'refund envoie scope, montant et motif' do
      req = stub(:post, "/connect/payments/#{pay}/refund/", { status: 'refunded' })
      client.connect.payments.refund(pay, scope: 'amount', amount: 500, reason: 'retour', idempotency_key: 'refund-1')
      expect(req.with(body: { scope: 'amount', amount: 500, reason: 'retour' }.to_json)).to have_been_requested
    end

    it 'refund refuse un scope inconnu sans appel réseau' do
      expect { client.connect.payments.refund(pay, scope: 'oups', idempotency_key: 'k') }
        .to raise_error(Sangho::SanghoValidationError, /scope/)
    end

    it 'freeze, unfreeze, retrieve et simulate_payment appellent les bonnes routes' do
      stub(:post, "/connect/payments/#{pay}/freeze/")
      stub(:post, "/connect/payments/#{pay}/unfreeze/")
      stub(:get, "/connect/payments/#{pay}/")
      stub(:post, "/connect/payments/#{pay}/simulate-payment/")
      client.connect.payments.freeze(pay)
      client.connect.payments.unfreeze(pay)
      client.connect.payments.retrieve(pay)
      client.connect.payments.simulate_payment(pay)
    end

    it 'refuse une clé publique' do
      pub = Sangho.new('pk_test_abc123456789')
      expect { pub.connect.payments.retrieve(pay) }.to raise_error(Sangho::SanghoPublicKeyError)
    end
  end

  describe 'erreurs' do
    it '403 platform_partner_required -> SanghoPlatformPartnerRequiredError' do
      stub(:get, '/connect/accounts/', { error: { code: 'platform_partner_required', message: 'Réservé' } }, status: 403)
      expect { client.connect.accounts.list }.to raise_error(Sangho::SanghoPlatformPartnerRequiredError) do |e|
        expect(e.code).to eq('platform_partner_required')
        expect(e.message).to eq('Réservé')
      end
    end

    it '409 account_not_claimed -> SanghoConflictError (et non une erreur d’idempotence)' do
      stub(:post, "/connect/accounts/#{acct}/kyc-session/",
           { error: { code: 'account_not_claimed', message: 'Non réclamé' } }, status: 409)
      expect { client.connect.accounts.create_kyc_session(acct, return_url: 'https://x') }
        .to raise_error(Sangho::SanghoConflictError, 'Non réclamé')
    end

    it '409 idempotency_conflict reste une SanghoIdempotencyError' do
      stub(:post, '/customers/', { code: 'idempotency_conflict' }, status: 409)
      expect { client.customers.create(email: 'a@b.ga', name: 'A') }.to raise_error(Sangho::SanghoIdempotencyError)
    end
  end
end
