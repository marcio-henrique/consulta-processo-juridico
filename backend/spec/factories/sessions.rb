FactoryBot.define do
  factory :session do
    user
    sequence(:token_digest) { |n| Digest::SHA256.hexdigest("fixture-token-#{n}") }
    user_agent { "RSpec" }
    ip_address { "127.0.0.1" }
    expires_at { 1.week.from_now }
  end
end
