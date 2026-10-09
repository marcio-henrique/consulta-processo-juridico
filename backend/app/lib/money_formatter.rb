# Formats monetary values for the API (Money type).
#
#   MoneyFormatter.amount(BigDecimal("10000"))  # => "10000.00"
#   MoneyFormatter.format(BigDecimal("13028.16")) # => "R$ 13.028,16"
module MoneyFormatter
  module_function

  # Decimal string with exactly two places, dot as separator.
  def amount(value)
    Kernel.format("%.2f", BigDecimal(value.to_s).round(2))
  end

  # pt-BR currency: "R$ 1.234,56".
  def format(value)
    integer, cents = amount(value).split(".")
    "R$ #{integer.reverse.scan(/\d{1,3}/).join(".").reverse},#{cents}"
  end
end
