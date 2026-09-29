# frozen_string_literal: true

module Sangho
  # Catégories larges (`error.type`). Les 7 premières sont exactement la taxonomie `type` renvoyée par le backend
  # (backend/api/exceptions.py) ; NETWORK_ERROR et TIMEOUT_ERROR sont propres au SDK (la requête n'a jamais abouti).
  KNOWN_ERROR_TYPES = %w[
    AUTHENTICATION_ERROR PERMISSION_ERROR NOT_FOUND_ERROR CONFLICT_ERROR VALIDATION_ERROR
    RATE_LIMIT_ERROR API_ERROR NETWORK_ERROR TIMEOUT_ERROR
  ].freeze

  # Erreur de base : toutes les erreurs Sangho en héritent.
  #
  # * +type+  : catégorie large (VALIDATION_ERROR, RATE_LIMIT_ERROR, NETWORK_ERROR…), pratique pour un +case+.
  # * +code+  : code métier précis renvoyé par le backend (AMOUNT_TOO_SMALL, CURRENCY_NOT_IN_PLAN…). Le catalogue est
  #   possédé par le backend et grandit : c'est une String, pas une énumération. Sans réponse du serveur (réseau,
  #   délai dépassé), il vaut +type+.
  class SanghoError < StandardError
    attr_reader :type, :code, :status_code, :raw

    def initialize(msg = nil, type: 'API_ERROR', status_code: nil, raw: {})
      super(msg)
      @raw = raw.is_a?(Hash) ? raw : {}
      @type = resolve_type(type)
      @code = (@raw[:code] || @type).to_s
      @status_code = status_code
    end

    # Identifiant de la requête (support), si le backend en a fourni un.
    def request_id
      raw[:request_id]
    end

    # Lien vers la documentation de ce code d'erreur, si fourni.
    def doc_url
      raw[:doc_url]
    end

    # Champ fautif, si fourni.
    def param
      raw[:param]
    end

    private

    # Un +type+ reconnu renvoyé par le backend prime (correspondance 1:1) ; sinon la catégorie de la sous-classe.
    def resolve_type(default)
      backend = raw[:type].to_s.upcase
      KNOWN_ERROR_TYPES.include?(backend) ? backend : default
    end
  end

  # 401 — clé API invalide, expirée ou absente.
  class SanghoAuthError < SanghoError
    def initialize(msg = 'Invalid or missing API key.', status_code: 401, raw: {})
      super(msg, type: 'AUTHENTICATION_ERROR', status_code: status_code, raw: raw)
    end
  end

  # 403 — opération réservée aux clés secrètes, appelée avec une clé publique.
  class SanghoPublicKeyError < SanghoError
    def initialize(msg = 'Public key not allowed for this operation.', status_code: 403, raw: {})
      super(msg, type: 'PERMISSION_ERROR', status_code: status_code, raw: raw)
      @code = (@raw[:code] || 'PUBLIC_KEY_NOT_ALLOWED').to_s
    end
  end

  # 403 — permissions insuffisantes.
  class SanghoPermissionError < SanghoError
    def initialize(msg = 'You do not have permission to perform this action.', status_code: 403, raw: {})
      super(msg, type: 'PERMISSION_ERROR', status_code: status_code, raw: raw)
    end
  end

  # 404 — ressource introuvable.
  class SanghoNotFoundError < SanghoError
    def initialize(msg = 'Resource not found.', status_code: 404, raw: {})
      super(msg, type: 'NOT_FOUND_ERROR', status_code: status_code, raw: raw)
    end
  end

  # 403 — la ressource est réservée aux Apps « Partenaire Plateforme » (routes Connect).
  class SanghoPlatformPartnerRequiredError < SanghoError
    def initialize(msg = 'This App is not a Platform Partner.', status_code: 403, raw: {})
      super(msg, type: 'PERMISSION_ERROR', status_code: status_code, raw: raw)
      @code = (@raw[:code] || 'platform_partner_required').to_s
    end
  end

  # 409 — conflit d'état métier (ex : +account_not_claimed+). Distinct de SanghoIdempotencyError.
  class SanghoConflictError < SanghoError
    def initialize(msg = 'Conflict.', status_code: 409, raw: {})
      super(msg, type: 'CONFLICT_ERROR', status_code: status_code, raw: raw)
    end
  end

  # 409 — clé d'idempotence réutilisée avec un corps différent.
  class SanghoIdempotencyError < SanghoError
    def initialize(msg = 'Idempotency key reused with different request parameters.', status_code: 409, raw: {})
      super(msg, type: 'CONFLICT_ERROR', status_code: status_code, raw: raw)
    end
  end

  # 422 — validation (erreurs champ par champ dans +field_errors+).
  class SanghoValidationError < SanghoError
    def initialize(msg = nil, status_code: 422, raw: {})
      super(msg || 'Validation error', type: 'VALIDATION_ERROR', status_code: status_code, raw: raw)
    end

    def field_errors
      fields = raw[:detail].is_a?(Hash) ? raw[:detail] : raw[:errors]
      fields.is_a?(Hash) ? fields : {}
    end
  end

  # 429 — trop de requêtes. +retry_after+ : délai (secondes) avant de réessayer.
  class SanghoRateLimitError < SanghoError
    attr_reader :retry_after

    def initialize(msg = nil, retry_after: 60, status_code: 429, raw: {})
      @retry_after = retry_after
      super(msg || "Rate limit exceeded. Retry after #{retry_after}s.",
            type: 'RATE_LIMIT_ERROR', status_code: status_code, raw: raw)
    end
  end

  # Aucune réponse du serveur (DNS, connexion refusée…). Catégorie propre au SDK.
  class SanghoNetworkError < SanghoError
    def initialize(msg = 'Network error. Please check your connection.')
      super(msg, type: 'NETWORK_ERROR')
    end
  end

  # Délai dépassé. Catégorie propre au SDK.
  class SanghoTimeoutError < SanghoError
    def initialize(timeout = nil)
      super(timeout ? "Request timed out after #{timeout}s." : 'Request timed out.', type: 'TIMEOUT_ERROR')
    end
  end

  # Signature de webhook refusée. +reason+ : +malformed+ (en-tête illisible, 400), +expired+ (horodatage hors
  # tolérance, 400) ou +mismatch+ (aucune signature ne correspond à un secret, 401).
  #
  # Sous-classe de SanghoError : +code+ garde les valeurs historiques (+invalid_signature+, +stale_event+).
  class SanghoWebhookSignatureError < SanghoError
    MALFORMED = 'malformed'
    EXPIRED = 'expired'
    MISMATCH = 'mismatch'

    attr_reader :reason

    def initialize(reason, msg)
      @reason = reason
      super(msg, type: reason == MISMATCH ? 'AUTHENTICATION_ERROR' : 'VALIDATION_ERROR',
                 status_code: reason == MISMATCH ? 401 : 400,
                 raw: { code: reason == EXPIRED ? 'stale_event' : 'invalid_signature' })
    end
  end
end
