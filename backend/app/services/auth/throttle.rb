module Auth
  # Counters for the abuse limits of spec 06 (requirement 5.3), stored in
  # Rack::Attack's cache so one store and one reset path serve both the
  # Rack-level throttle (config/initializers/rack_attack.rb) and these
  # per-operation limits.
  #
  # Operation-level counting (instead of matching the HTTP body in Rack) means
  # a client cannot dodge the limit by aliasing or batching mutations in one
  # request. Keys are hashed so emails and IPs never sit in the cache in clear.
  module Throttle
    LIMITS = {
      sign_in_ip: { limit: 5, period: 1.minute },
      sign_in_email: { limit: 5, period: 1.minute },
      sign_up_ip: { limit: 10, period: 1.hour },
      generate_summary_user: { limit: 10, period: 1.minute }
    }.freeze

    module_function

    # Counts one attempt and returns true while the caller is within the limit.
    def allow?(name, key)
      rule = LIMITS.fetch(name)
      hashed = Digest::SHA256.hexdigest(key.to_s)
      Rack::Attack.cache.count("auth/#{name}:#{hashed}", rule[:period]) <= rule[:limit]
    end

    def rate_limited_error
      Errors::Messages.build("RATE_LIMITED", Errors::Messages::RATE_LIMITED)
    end
  end
end
