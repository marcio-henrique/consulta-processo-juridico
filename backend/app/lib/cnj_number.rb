# Pure-Ruby parser/validator for Brazilian CNJ lawsuit numbers
# (format NNNNNNN-DD.AAAA.J.TR.OOOO, CNJ Resolution 65/2008).
#
#   CnjNumber.parse("10013993120238260070").formatted
#   # => "1001399-31.2023.8.26.0070"
module CnjNumber
  DIGITS_LENGTH = 20

  Result = Struct.new(:formatted, :segments, :error, keyword_init: true) do
    def valid?
      error.nil?
    end
  end

  module_function

  # Normalizes and validates +input+. Never raises: failures are reported
  # through Result#error (:invalid_format or :invalid_check_digit).
  def parse(input)
    digits = input.to_s.gsub(/\D/, "")
    return Result.new(error: :invalid_format) unless digits.length == DIGITS_LENGTH

    segments = {
      sequence: digits[0, 7],
      check_digits: digits[7, 2],
      year: digits[9, 4],
      justice_branch: digits[13, 1],
      court: digits[14, 2],
      origin: digits[16, 4]
    }
    formatted = format_segments(segments)
    expected = check_digits(**segments.except(:check_digits))
    error = segments[:check_digits] == expected ? nil : :invalid_check_digit

    Result.new(formatted: formatted, segments: segments, error: error)
  end

  # 98 - (sequence + year + branch + court + origin + "00") mod 97, zero padded.
  def check_digits(sequence:, year:, justice_branch:, court:, origin:)
    base = "#{sequence}#{year}#{justice_branch}#{court}#{origin}00".to_i
    format("%02d", 98 - (base % 97))
  end

  def format_segments(segments)
    "#{segments[:sequence]}-#{segments[:check_digits]}.#{segments[:year]}." \
      "#{segments[:justice_branch]}.#{segments[:court]}.#{segments[:origin]}"
  end
end
