FactoryBot.define do
  factory :lawsuit do
    sequence(:number) { |n| format("10%05d-%02d.2023.8.26.0070", n, n % 100) }
    forum { "Foro de Batatais" }
    court { "2ª Vara Cível" }
    value { 10_000.00 }
    number_of_authors { 1 }

    trait :with_movements do
      transient do
        movements_count { 5 }
      end

      after(:create) do |lawsuit, evaluator|
        create_list(:movement, evaluator.movements_count, lawsuit: lawsuit)
      end
    end
  end
end
