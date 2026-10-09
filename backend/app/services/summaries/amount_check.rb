module Summaries
  # Guards against numbers the model garbled or invented. Every amount written
  # as "R$ <number>" in the answer must have the same value as some number in
  # the source (the prompt). Values are compared, not spellings, so "R$ 8.000"
  # matches "R$ 8.000,00". Amounts with broken separators ("R$ 8,000,00") never
  # match.
  #
  #   Summaries::AmountCheck.call(answer, prompt.user) # => ["8,000,00"] (offending amounts)
  class AmountCheck
    AMOUNT_IN_ANSWER = /R\$\s*(\d[\d.,]*\d|\d)/
    NUMBER_IN_SOURCE = /\d[\d.,]*\d|\d/
    BRL_FORMAT = /\A(?:\d{1,3}(?:\.\d{3})+|\d+)(?:,\d{1,2})?\z/

    def self.call(answer, source)
      known = source.to_s.scan(NUMBER_IN_SOURCE).filter_map { |raw| value(raw) }.to_set
      answer.to_s.scan(AMOUNT_IN_ANSWER).flatten.uniq.reject do |raw|
        number = value(raw)
        number && known.include?(number)
      end
    end

    # BigDecimal for a well-formed Brazilian number, nil otherwise.
    def self.value(raw)
      return nil unless raw.match?(BRL_FORMAT)

      BigDecimal(raw.delete(".").tr(",", "."))
    end
    private_class_method :value
  end
end
