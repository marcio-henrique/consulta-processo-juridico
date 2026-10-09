module Auth
  # Cookie attributes for the session token (docs/domains/authentication.md
  # section 3). Secure is enabled in production only, so plain
  # http://localhost works in development and in the demo.
  module SessionCookie
    NAME = :_lawsuit_session

    module_function

    def options(raw_token, expires_at:, secure: Rails.env.production?)
      {
        value: raw_token,
        expires: expires_at,
        httponly: true,
        same_site: :lax,
        secure: secure,
        path: "/"
      }
    end
  end
end
