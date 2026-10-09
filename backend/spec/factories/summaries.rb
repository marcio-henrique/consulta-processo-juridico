FactoryBot.define do
  factory :summary do
    lawsuit
    body { "O processo tramita normalmente. Este é um resumo de teste." }
    sequence(:movements_digest) { |n| Digest::SHA256.hexdigest("fixture-#{n}") }
    prompt_version { "v1" }
    provider { "fake" }
    model { "fake-v1" }
    input_tokens { 100 }
    output_tokens { 80 }
  end
end
