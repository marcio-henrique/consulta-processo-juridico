FactoryBot.define do
  factory :lawsuit do
    # Unique, valid CNJ numbers (the model validates the check digit).
    sequence(:number) do |n|
      parts = { sequence: format("%07d", 1_000_000 + n), year: "2023", justice_branch: "8", court: "26", origin: "0070" }
      "#{parts[:sequence]}-#{CnjNumber.check_digits(**parts)}.2023.8.26.0070"
    end
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
