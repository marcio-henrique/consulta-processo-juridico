module Auth
  # Creates a session row for +user+ and returns [session, raw_token].
  module CreateSession
    module_function

    def call(user, user_agent: nil, ip_address: nil)
      raw, digest = SessionToken.generate
      session = user.sessions.create!(
        token_digest: digest,
        user_agent: user_agent.to_s.truncate(255).presence,
        ip_address: ip_address.to_s.truncate(45).presence,
        expires_at: Session::LIFETIME.from_now
      )
      [ session, raw ]
    end
  end
end
