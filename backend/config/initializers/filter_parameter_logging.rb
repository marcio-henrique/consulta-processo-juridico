# Parameters filtered from the request log (docs/security.md section 4).
# GraphQL carries passwords inside `variables`, and inline literals inside
# `query`, so both are filtered whole. Cookies and Authorization headers are
# not logged by Rails; the patterns below are a second line of defense for
# anything that ends up in params.
Rails.application.config.filter_parameters += [
  :passw, :email, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn, :cvv, :cvc,
  :authorization, :cookie, :variables, :query,
  /api[-_]?key/i, /session/i
]
