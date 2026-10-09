# Throttle counters live in Rack::Attack's cache; start every example clean so
# specs never throttle each other.
RSpec.configure do |config|
  config.before { Rack::Attack.cache.store.clear }
end
