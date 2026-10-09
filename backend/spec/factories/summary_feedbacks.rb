FactoryBot.define do
  factory :summary_feedback do
    summary
    user
    helpful { true }
  end
end
