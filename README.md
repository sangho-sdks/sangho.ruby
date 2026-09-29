# Sangho Ruby SDK

SDK officiel Ruby pour l'API [Sangho](https://sangho.ga) — paiements XAF pour l'Afrique.

[![Docs](https://img.shields.io/badge/docs-docs.sangho.ga-navy)](https://docs.sangho.ga/api/sdks/ruby/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## Installation

```bash
gem install sangho
```

Ou dans votre `Gemfile` :

```ruby
gem 'sangho'
```

Ruby ≥ 3.1.

## Démarrage

```ruby
require 'sangho'

client = Sangho.new('sk_test_...')   # clé de test ; en production : sk_prod_...

customer = client.customers.create(email: 'jean@example.com', name: 'Jean Ondo')
puts customer[:id]                   # les réponses sont des Hash aux clés symboles

intent = client.payment_intents.create(amount: 5000, customer: customer[:id])
puts intent[:status]
```

Configuration globale (optionnelle) :

```ruby
Sangho.configure do |c|
  c.api_key = ENV.fetch('SANGHO_SECRET_KEY')
  c.timeout = 30
end
client = Sangho::SanghoClient.new
```

Options du client : `base_url:` (défaut `https://api.sangho.ga/v1`, HTTPS obligatoire hors `localhost`), `timeout:`
(secondes, défaut 30), `max_retries:` (défaut 3).

Les clés commencent par `pk_test_`, `sk_test_` (bac à sable) ou `pk_prod_`, `sk_prod_` (production). Une **clé
publique** (`pk_…`) ne peut appeler que `checkout_sessions.retrieve` ; tout le reste exige une clé secrète.

## Listes paginées

```ruby
page = client.customers.list(page: 1, page_size: 20)
page[:count]   # total
page[:data]    # éléments de la page (et non :results)
page[:next]    # URL de la page suivante ou nil
```

## Gestion des erreurs

Toutes les erreurs héritent de `Sangho::SanghoError` et exposent `type` (catégorie large), `code` (code métier précis du
backend), `status_code`, `param`, `request_id` et `raw` :

```ruby
begin
  client.payment_intents.create(amount: 1, customer: 'cus_1')
rescue Sangho::SanghoValidationError => e
  e.type          # => "VALIDATION_ERROR"
  e.code          # => "AMOUNT_TOO_SMALL"
  e.field_errors  # => { amount: ["…"] }
  e.request_id    # à communiquer au support
rescue Sangho::SanghoRateLimitError => e
  sleep e.retry_after
rescue Sangho::SanghoNetworkError, Sangho::SanghoTimeoutError
  # la requête n'a pas abouti
end
```

| Classe                     | Statut | `type`                 |
| -------------------------- | ------ | ---------------------- |
| `SanghoAuthError`          | 401    | `AUTHENTICATION_ERROR` |
| `SanghoPublicKeyError`     | 403    | `PERMISSION_ERROR` (code `PUBLIC_KEY_NOT_ALLOWED`) |
| `SanghoPermissionError`    | 403    | `PERMISSION_ERROR`     |
| `SanghoNotFoundError`      | 404    | `NOT_FOUND_ERROR`      |
| `SanghoIdempotencyError`   | 409    | `CONFLICT_ERROR`       |
| `SanghoValidationError`    | 422    | `VALIDATION_ERROR`     |
| `SanghoRateLimitError`     | 429    | `RATE_LIMIT_ERROR`     |
| `SanghoNetworkError`       | —      | `NETWORK_ERROR`        |
| `SanghoTimeoutError`       | —      | `TIMEOUT_ERROR`        |

Les erreurs `429` (en respectant `retry_after`), `5xx` et réseau sont réessayées avec un backoff exponentiel
(`max_retries`). Les autres `4xx` ne le sont jamais. Chaque `POST` envoie une `Idempotency-Key` (UUID).

## Webhooks

```ruby
event = Sangho::Resources::Webhooks.construct_event(request.body.read, request.headers['Sangho-Signature'], ENV['WEBHOOK_SECRET'])
```

Lève `Sangho::SanghoError` si la signature est invalide ou l'événement périmé (tolérance 300 s par défaut).

## Ressources

`account` · `addresses` · `apps` · `checkout_sessions` · `customers` · `invoices` · `partners` (lecture seule) ·
`payment_intents` · `payment_links` · `payment_methods` · `products` · `receipts` · `refunds` · `sandbox` · `security` ·
`subscriptions` · `terminal` (`readers`, `sessions`, `offline`) · `transactions` · `webhooks`.

Documentation complète : [docs.sangho.ga](https://docs.sangho.ga/api/sdks/ruby/).

## Développement

```bash
make install   # bundle install
make test      # rspec (specs unitaires ; spec/integration vise l'API réelle)
make lint      # rubocop
```

Voir [CONTRIBUTING.md](CONTRIBUTING.md) et [CHANGELOG.md](CHANGELOG.md).

## Licence

MIT
