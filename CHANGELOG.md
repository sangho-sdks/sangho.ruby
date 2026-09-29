# Changelog

Tous les changements notables sont documentés ici.

Format basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.0.0/).
Ce projet respecte le [Semantic Versioning](https://semver.org/lang/fr/).

---

## [0.2.0] - 2026-09-29

> **Versionnement.** La version 1.0.0 ci-dessous était interne : ce SDK n'a jamais été publié (RubyGems). La
> numérotation est réalignée sur celle du SDK JS (`@sanghosdk/js` 0.1.4, seul SDK publié), comme le demande
> `CONTRIBUTING.md` (« tous les SDKs sont versionnés de façon synchronisée »). Version courante : **0.2.0** (0.1.4 = alignement sur l'API ; 0.2.0 y ajoute Connect, la vérification des signatures
> webhook et l'idempotence, comme les SDK JS, Python et PHP).

### Added
- **Paiement sécurisé à la livraison (Connect)** — `client.connect.payments` : `retrieve`, `release`, `refund` (`scope` :
  `product` / `full` / `amount`), `freeze`, `unfreeze`, `simulate_payment` (sandbox) ; `client.connect.accounts` :
  `create` (idempotent par `external_id`), `retrieve`, `list`, `reissue_claim_token`, `create_kyc_session`, `balance`,
  `create_payout`, `list_payouts`.
- `idempotency_key:` OBLIGATOIRE sur `release`, `refund` et `create_payout` : `SanghoValidationError` levée avant tout
  appel réseau si elle manque.
- `idempotency_key:` accepté par toutes les méthodes d'écriture ; sans clé, un POST n'est plus rejoué après un délai
  dépassé / une erreur réseau (risque de doublon côté serveur).
- `checkout_sessions.create(line_items:, success_url:, currency: 'XAF', connect: {…})` (l'ancien `amount:` est converti en
  une ligne ad hoc, avec un avertissement) ; `payment_intents.create(amount:, currency:, customer_email:)`.
- Erreurs `SanghoPlatformPartnerRequiredError` (403), `SanghoConflictError` (409 d'état métier, ex : `account_not_claimed`)
  et `SanghoWebhookSignatureError` (`reason` : `malformed` / `expired` / `mismatch`, sous-classe de `SanghoError`).
- `Webhooks.construct_event` accepte une liste de secrets (rotation) et plusieurs `v1` ; `Webhooks.generate_test_header`
  produit un en-tête valide pour tester son endpoint.

### Changed
- Les réponses d'erreur Connect au format `{"error": {"code", "message"}}` sont lues comme le format plat des autres routes.

### Fixed
- **Bloquant** : toutes les requêtes partaient vers `https://api.sangho.ga/<ressource>/` au lieu de
  `…/v1/<ressource>/` (Faraday ignore le préfixe de l'URL de base quand le chemin commence par `/`).
- **Bloquant** : le gem ne pouvait pas être construit ni chargé (`sangho.gemspec` exigeait `lib/sangho/version`, or
  `version.rb` était à la racine). `required_ruby_version` passe de `>= 4.0` à `>= 3.1`.
- Les clés de production `pk_prod_` / `sk_prod_` étaient refusées (le SDK n'acceptait que `pk_live_` / `sk_live_`,
  préfixe qui n'existe pas côté API).
- URL par défaut : `https://api.sangho.ga/v1` (et non `.com`).
- `security.retrieve` / `security.update` appelaient `/security/` ; les routes sont `/security/me/` et
  `/security/update_me/`.
- `SanghoRateLimitError#retry_after` lisait `retry_later` (clé inexistante) : lit maintenant `retry_after`, puis
  l'en-tête `Retry-After`.
- La signature des webhooks était comparée avec `==` : comparaison en temps constant.
- `checkout_sessions.retrieve` accepte une clé publique (page de confirmation côté navigateur), comme les autres SDK.

### Added
- Ressources `account`, `addresses`, `sandbox` (`reset`) et `terminal` (`readers`, `sessions`, `offline`).
- `apps.keys`, `checkout_sessions.delete`, `invoices.get_pdf_url`, `receipts.get_pdf_url`,
  `payment_intents.delete`, `payment_links.archive/restore/delete`, `payment_methods.attach/detach/set_default`,
  `transactions.update/cancel`, `subscriptions.reactivate`, `webhooks.enable/disable/retrieve_delivery`.
- Erreurs typées comme le SDK JS : `type` (catégorie), `code` (code métier), `param`, `request_id`, `doc_url` ;
  `SanghoNetworkError` et `SanghoTimeoutError`.
- Retry avec backoff exponentiel sur `429` (en respectant `retry_after`), tout `5xx` et les erreurs réseau
  (`max_retries:`) ; en-têtes `X-Sangho-SDK` et `X-Sangho-Environment` ; validation de la clé et de l'URL de base.
- `LICENSE` (MIT), `.rubocop.yml`, specs unitaires (client HTTP, alignement sur l'API).

### Changed
- **Breaking** : les listes paginées exposent `data` (et non `results`), conformément à la pagination réelle de l'API.
- **Breaking** : constructeurs d'erreurs (`type:`), `SanghoRateLimitError.new(msg, retry_after:)`.
- `customers.list_payment_methods(id)` filtre `GET /payment-methods/?customer=<id>`.

### Removed
Méthodes qui appelaient des routes **inexistantes** côté API (elles répondaient 404/405) :
`apps.roll_secret`, `customers.list_transactions` (l'API n'a pas de filtre `customer` sur les transactions),
`invoices.finalize`, `partners.create/update/delete` (ressource en lecture seule),
`payment_links.deactivate` (utiliser `archive`), `payment_methods.create/update/delete`, `products.archive/restore`,
`receipts.send`, `refunds.update`, `security.roll_secret_key/list_sessions/revoke_session`.

---

## [1.0.0] - 2026-04-01

### Added

- Version initiale du SDK
- Support de toutes les ressources : apps, customers, products, payment_intents,
  checkout_sessions, invoices, transactions, refunds, subscriptions,
  payment_methods, webhooks, payment_links, addresses, partners
- Gestion complète des erreurs (auth, validation, rate limit, réseau)
- Pagination via ListResponse
