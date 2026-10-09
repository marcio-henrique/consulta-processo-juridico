# Security headers on every response (SEC-1; docs/security.md S11, S12).
#
# A tiny Rack middleware at the top of the stack, so even errors raised by
# other middleware (bad JSON, routing errors, rack-attack 429) carry them. It
# also overrides the looser Rails defaults (for example Referrer-Policy).
# The strict CSP is for the API's own responses; the Vite dev server that
# serves the SPA in development needs a looser one for HMR and is configured
# separately.
class SecurityHeaders
  CONTENT_SECURITY_POLICY =
    "default-src 'self'; script-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'self'".freeze

  BASE_HEADERS = {
    "Content-Security-Policy" => CONTENT_SECURITY_POLICY,
    "X-Content-Type-Options" => "nosniff",
    "Referrer-Policy" => "same-origin",
    "X-Frame-Options" => "DENY"
  }.freeze

  # Browsers ignore HSTS over plain http, so sending it is harmless on
  # localhost; it is limited to production because that is where TLS exists.
  HSTS = "max-age=63072000; includeSubDomains".freeze

  def initialize(app, rails_env: Rails.env)
    @app = app
    @headers = BASE_HEADERS.dup
    @headers["Strict-Transport-Security"] = HSTS if rails_env.production?
    @headers.freeze
  end

  def call(env)
    status, headers, body = @app.call(env)
    @headers.each { |name, value| headers[name] = value }
    [ status, headers, body ]
  end
end

Rails.application.config.middleware.insert_before(0, SecurityHeaders)
