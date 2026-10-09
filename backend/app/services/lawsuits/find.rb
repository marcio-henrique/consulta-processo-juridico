module Lawsuits
  # Finds a lawsuit by CNJ number in any common format (formatted, digits-only,
  # surrounding whitespace). Exact match on the canonical number: no LIKE.
  #
  #   Lawsuits::Find.call("10013993120238260070").lawsuit
  class Find
    Result = Struct.new(:lawsuit, :error_code, keyword_init: true) do
      def success?
        error_code.nil?
      end
    end

    def self.call(raw)
      new(raw).call
    end

    def initialize(raw)
      @raw = raw
    end

    def call
      parsed = CnjNumber.parse(@raw)
      return Result.new(error_code: :INVALID_CNJ) unless parsed.valid?

      lawsuit = Lawsuit.find_by(number: parsed.formatted)
      return Result.new(error_code: :NOT_FOUND) if lawsuit.nil?

      Result.new(lawsuit: lawsuit)
    end
  end
end
