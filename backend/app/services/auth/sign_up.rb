module Auth
  class SignUp
    def self.call(**args)
      new.call(**args)
    end

    def call(email:, password:, user_agent: nil, ip_address: nil)
      user = User.new(email: email, password: password)
      return failure(user.errors) unless saved?(user)

      session, raw = CreateSession.call(user, user_agent: user_agent, ip_address: ip_address)
      Result.new(user: user, session: session, token: raw, errors: [])
    end

    private

    def saved?(user)
      user.save
    rescue ActiveRecord::RecordNotUnique
      user.errors.add(:email, Errors::Messages::EMAIL_TAKEN)
      false
    end

    def failure(model_errors)
      errors = model_errors.map do |error|
        Errors::Messages.build("VALIDATION_FAILED", error.message, field: error.attribute.to_s)
      end
      Result.new(errors: errors)
    end
  end
end
