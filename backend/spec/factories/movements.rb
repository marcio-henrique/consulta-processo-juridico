FactoryBot.define do
  factory :movement do
    lawsuit
    occurred_on { Date.new(2024, 6, 10) }
    title { "Ato Ordinatório - Intimação - DJE" }
    content { "Relação: 0100/2024\nData da Publicação: 11/06/2024" }
    sequence(:source_row) { |n| n }
  end
end
