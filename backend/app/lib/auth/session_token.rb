module Auth
  # Opaque session tokens (ADR-0004): 32 random bytes, URL-safe base64, sent
  # to the browser once. Only the SHA-256 digest is stored, so a database leak
  # does not expose usable sessions.
  module SessionToken
    BYTES = 32

    module_function

    # Returns [raw_token, digest].
    def generate
      raw = SecureRandom.urlsafe_base64(BYTES)
      [ raw, digest(raw) ]
    end

    def digest(raw)
      Digest::SHA256.hexdigest(raw.to_s)
    end
  end
end
