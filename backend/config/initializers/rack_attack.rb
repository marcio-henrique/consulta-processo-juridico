# Throttling (spec 06, AU-6; docs/security.md S3, S9).
#
# - Per-operation limits (sign in, sign up, generateSummary) are enforced where
#   the operation runs, see Auth::Throttle, using this same cache.
# - Below is the coarse Rack-level safety net: one IP may not flood /graphql.
#
# The store is in-process memory: fine for the single-container demo. Behind
# several app processes, point it at a shared cache (for example Redis).
Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

Rack::Attack.throttle("graphql/ip", limit: 300, period: 5.minutes) do |request|
  request.ip if request.post? && request.path == "/graphql"
end

Rack::Attack.throttled_responder = lambda do |request|
  match = request.env["rack.attack.match_data"] || {}
  period = match[:period].to_i
  retry_after = period.positive? ? period - (match[:epoch_time].to_i % period) : 60
  body = {
    errors: [ { code: "RATE_LIMITED", message: Errors::Messages::RATE_LIMITED } ]
  }.to_json
  [ 429, { "Content-Type" => "application/json", "Retry-After" => retry_after.to_s }, [ body ] ]
end
