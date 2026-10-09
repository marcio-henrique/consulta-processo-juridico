module Mutations
  # Mutation.signIn: verifies credentials and starts a session. The failure
  # message is the same for unknown emails and wrong passwords. Attempts are
  # throttled per IP and per email before the password is checked.
  class SignIn
    def self.call(input:, context:)
      return { user: nil, errors: [ Auth::Throttle.rate_limited_error ] } unless within_limits?(input, context)

      result = Auth::SignIn.call(
        email: input[:email],
        password: input[:password],
        user_agent: context[:user_agent],
        ip_address: context[:ip_address]
      )
      AuthSupport.start_session(result, context) if result.success?
      AuthSupport.payload(result)
    end

    # Both counters are always incremented (no short-circuit), so an attacker
    # cannot keep one dimension fresh while exhausting the other.
    def self.within_limits?(input, context)
      by_ip = Auth::Throttle.allow?(:sign_in_ip, context[:ip_address] || "unknown")
      by_email = Auth::Throttle.allow?(:sign_in_email, User.normalize_email(input[:email]))
      by_ip && by_email
    end
    private_class_method :within_limits?
  end
end
