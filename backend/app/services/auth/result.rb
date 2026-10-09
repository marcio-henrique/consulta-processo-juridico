module Auth
  # Outcome of SignUp/SignIn. `token` is the raw session token (only available
  # right after creation, to be put in the cookie); `errors` are
  # UserError-shaped hashes ({ code:, message:, field: }).
  Result = Struct.new(:user, :session, :token, :errors, keyword_init: true) do
    def success?
      errors.blank?
    end
  end
end
