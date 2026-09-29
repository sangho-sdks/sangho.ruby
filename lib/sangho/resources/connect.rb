# frozen_string_literal: true

module Sangho
  module Resources
    # client.connect.{accounts, payments} — marketplace / paiement avec répartition. Clé secrète uniquement.
    #
    # Réservé aux Apps ayant le statut **Partenaire Plateforme** (approuvé par Sangho) : une App marchande
    # ordinaire reçoit un 403 SanghoPlatformPartnerRequiredError sur n'importe quel appel.
    class Connect < BaseResource
      attr_reader :accounts, :payments

      def initialize(http)
        super
        @accounts = ConnectAccounts.new(http)
        @payments = ConnectPayments.new(http)
      end
    end

    # Comptes des vendeurs d'une plateforme et KYC hébergé par Sangho.
    class ConnectAccounts < BaseResource
      PATH = '/connect/accounts/'

      # Crée (ou retrouve) le compte d'un vendeur — IDEMPOTENT par +external_id+. +claim_token+ n'est renvoyé QU'À la
      # création : transmettez-le au vendeur sans le stocker ni le journaliser (+reissue_claim_token+ en émet un nouveau).
      def create(external_id:, email:, idempotency_key: nil, **opts)
        @http.assert_secret_key!('connect.accounts.create')
        @http.post(PATH, { external_id: external_id, email: email }.merge(opts), idempotency_key: idempotency_key)
      end

      def retrieve(id)
        @http.assert_secret_key!('connect.accounts.retrieve')
        @http.get("#{PATH}#{id}/")
      end

      def list
        @http.assert_secret_key!('connect.accounts.list')
        @http.get(PATH)
      end

      # Réémet le jeton de réclamation d'un compte encore +pending_claim+ ; l'ancien est invalidé.
      def reissue_claim_token(id)
        @http.assert_secret_key!('connect.accounts.reissue_claim_token')
        @http.post("#{PATH}#{id}/claim-token/")
      end

      # Lance le KYC hébergé par Sangho ; redirigez le vendeur vers +session[:url]+ (valable environ une heure).
      def create_kyc_session(id, return_url:, refresh_url: nil, idempotency_key: nil)
        @http.assert_secret_key!('connect.accounts.create_kyc_session')
        body = { return_url: return_url }
        body[:refresh_url] = refresh_url unless refresh_url.nil? || refresh_url.empty?
        @http.post("#{PATH}#{id}/kyc-session/", body, idempotency_key: idempotency_key)
      end

      # Soldes : available, held, frozen, reserve, negative, paid_out (chaînes décimales).
      def balance(id)
        @http.assert_secret_key!('connect.accounts.balance')
        @http.get("#{PATH}#{id}/balance/")
      end

      # Retrait vers Mobile Money / banque, limité au disponible POSITIF. Clé d'idempotence OBLIGATOIRE.
      def create_payout(id, amount:, destination:, idempotency_key:)
        @http.assert_secret_key!('connect.accounts.create_payout')
        key = ConnectPayments.require_key('connect.accounts.create_payout', idempotency_key)
        @http.post("#{PATH}#{id}/payouts/", { amount: amount, destination: destination }, idempotency_key: key)
      end

      def list_payouts(id)
        @http.assert_secret_key!('connect.accounts.list_payouts')
        @http.get("#{PATH}#{id}/payouts/")
      end
    end

    # Instructions sur un paiement avec répartition (+cpay_…+). La plateforme DÉCIDE, Sangho EXÉCUTE.
    # Création : +client.checkout_sessions.create(..., connect: {…})+.
    class ConnectPayments < BaseResource
      PATH = '/connect/payments/'
      REFUND_SCOPES = %w[product full amount].freeze

      # Les écritures d'argent exigent une clé d'idempotence STABLE (ex. +release-<commande>+) : un rejeu ne doit
      # jamais dupliquer l'opération.
      def self.require_key(method, key)
        return key unless key.nil? || key.to_s.empty?

        raise SanghoValidationError.new("'#{method}' exige une clé d'idempotence stable, ex : 'release-<order_id>'.",
                                        raw: { message: 'idempotency_key required' })
      end

      def retrieve(id)
        @http.assert_secret_key!('connect.payments.retrieve')
        @http.get("#{PATH}#{id}/")
      end

      # Libère les fonds bloqués (ou gelés) au vendeur, commission retenue. Événement +funds.released+.
      def release(id, idempotency_key:)
        @http.assert_secret_key!('connect.payments.release')
        key = self.class.require_key('connect.payments.release', idempotency_key)
        @http.post("#{PATH}#{id}/release/", {}, idempotency_key: key)
      end

      # Rembourse le client. +scope+ : +product+ (livraison conservée), +full+ (produit + livraison) ou +amount+
      # (montant libre, +amount:+ requis).
      def refund(id, scope:, idempotency_key:, amount: nil, reason: nil)
        @http.assert_secret_key!('connect.payments.refund')
        key = self.class.require_key('connect.payments.refund', idempotency_key)
        unless REFUND_SCOPES.include?(scope.to_s)
          raise SanghoValidationError.new('scope doit valoir "product", "full" ou "amount".',
                                          raw: { message: 'invalid scope' })
        end
        body = { scope: scope.to_s }
        body[:amount] = amount unless amount.nil?
        body[:reason] = reason unless reason.nil? || reason.empty?
        @http.post("#{PATH}#{id}/refund/", body, idempotency_key: key)
      end

      # Bloqué → gelé (litige) ; événement +funds.frozen+.
      def freeze(id, idempotency_key: nil)
        @http.assert_secret_key!('connect.payments.freeze')
        @http.post("#{PATH}#{id}/freeze/", {}, idempotency_key: idempotency_key)
      end

      # Gelé → bloqué ; événement +funds.unfrozen+.
      def unfreeze(id, idempotency_key: nil)
        @http.assert_secret_key!('connect.payments.unfreeze')
        @http.post("#{PATH}#{id}/unfreeze/", {}, idempotency_key: idempotency_key)
      end

      # Sandbox uniquement : simule l'encaissement du paiement.
      def simulate_payment(id)
        @http.assert_secret_key!('connect.payments.simulate_payment')
        @http.post("#{PATH}#{id}/simulate-payment/")
      end
    end
  end
end
