module Auth
  # Resolves the raw cookie token to a live Session (or nil). Expired rows are
  # purged lazily when they are presented.
  class Authenticate
    def self.call(raw_token)
      return nil if raw_token.blank?

      session = Session.includes(:user).find_by(token_digest: Session.digest(raw_token))
      return nil unless session

      if session.expired?
        session.destroy
        return nil
      end

      session
    end
  end
end
