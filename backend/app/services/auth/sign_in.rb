module Auth
  class SignIn
    # Compared against when the email is unknown, so unknown emails cost about
    # the same as wrong passwords (no user enumeration by timing).
    DUMMY_DIGEST = BCrypt::Password.create("dummy-password-for-timing", cost: BCrypt::Engine.cost).to_s.freeze

    def self.call(**args)
      new.call(**args)
    end

    def call(email:, password:, user_agent: nil, ip_address: nil)
      user = User.find_by(email: User.normalize_email(email))
      return invalid_credentials unless valid_password?(user, password.to_s)

      session, raw = CreateSession.call(user, user_agent: user_agent, ip_address: ip_address)
      Result.new(user: user, session: session, token: raw, errors: [])
    end

    private

    def valid_password?(user, password)
      digest = user&.password_digest || DUMMY_DIGEST
      matches = BCrypt::Password.new(digest) == password
      user.present? && matches
    end

    def invalid_credentials
      Result.new(errors: [
        Errors::Messages.build("UNAUTHENTICATED", Errors::Messages::INVALID_CREDENTIALS)
      ])
    end
  end
end
