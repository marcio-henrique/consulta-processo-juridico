module Mutations
  # Mutation.signUp: creates the account and starts a session (10 per hour
  # per IP).
  class SignUp
    def self.call(input:, context:)
      unless Auth::Throttle.allow?(:sign_up_ip, context[:ip_address] || "unknown")
        return { user: nil, errors: [ Auth::Throttle.rate_limited_error ] }
      end

      result = Auth::SignUp.call(
        email: input[:email],
        password: input[:password],
        user_agent: context[:user_agent],
        ip_address: context[:ip_address]
      )
      AuthSupport.start_session(result, context) if result.success?
      AuthSupport.payload(result)
    end
  end
end
