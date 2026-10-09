require "bigdecimal"
require "date"

# Exact parsing of Brazilian-formatted values found in the lawsuits CSV.
# Money never goes through Float.
module BrlParser
  class ParseError < StandardError; end

  # "." thousands separator, "," decimal separator (at most 2 decimal digits).
  MONEY_FORMAT = /\A(?:\d{1,3}(?:\.\d{3})+|\d+)(?:,\d{1,2})?\z/

  module_function

  # "13.028,16" => BigDecimal("13028.16"); "10.168,2" => BigDecimal("10168.2")
  def money(raw)
    text = raw.to_s.strip
    raise ParseError, "money is blank" if text.empty?
    raise ParseError, "invalid money value: #{text.inspect}" unless MONEY_FORMAT.match?(text)

    BigDecimal(text.delete(".").tr(",", "."))
  end

  # "5/12/2023" => Date.new(2023, 12, 5)
  def date(raw)
    text = raw.to_s.strip
    raise ParseError, "date is blank" if text.empty?
    raise ParseError, "invalid date: #{text.inspect}" unless %r{\A\d{1,2}/\d{1,2}/\d{4}\z}.match?(text)

    Date.strptime(text, "%d/%m/%Y")
  rescue Date::Error
    raise ParseError, "invalid date: #{text.inspect}"
  end
end
