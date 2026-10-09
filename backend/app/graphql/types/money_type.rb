module Types
  class MoneyType < Types::BaseObject
    graphql_name "Money"

    field :amount, String, null: false, description: "Decimal string with two places, for example 10000.00."
    field :formatted, String, null: false, description: "pt-BR currency, for example R$ 10.000,00."
  end
end
