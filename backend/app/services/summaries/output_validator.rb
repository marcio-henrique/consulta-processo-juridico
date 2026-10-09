module Summaries
  # Normalizes and checks the model's answer (docs/domains/ai-summary.md 2.5).
  #
  # `.call` strips markdown artifacts, rebuilds clean paragraphs, rejects blank
  # output (Llm::ProviderError) and reports blocklisted jargon without blocking.
  # `.enforce` is the last resort when the answer still breaks the limits after
  # the corrective retry: merge extra paragraphs into the third and cut at a
  # sentence boundary under MAX_CHARS.
  class OutputValidator
    MAX_PARAGRAPHS = 3
    MAX_CHARS = 2_000
    JARGON = [
      "data venia", "ex vi", "inaudita altera pars", "ad cautelam", "mutatis mutandis",
      "ipso facto", "in limine", "sub judice", "ad hoc", "ex officio"
    ].freeze
    JARGON_PATTERN = /(?<![[:alpha:]])(#{JARGON.map { |term| Regexp.escape(term) }.join('|')})(?![[:alpha:]])/i

    Output = Struct.new(:text, :paragraphs, :jargon, keyword_init: true) do
      def within_limits?
        paragraphs <= MAX_PARAGRAPHS && text.length <= MAX_CHARS
      end
    end

    def self.call(raw)
      text = clean(raw)
      raise Llm::ProviderError, "LLM returned an empty summary" if text.empty?

      jargon = text.scan(JARGON_PATTERN).flatten.map(&:downcase).uniq
      Rails.logger.warn("Summary jargon detected terms=#{jargon.join(',')}") if jargon.any?
      Output.new(text: text, paragraphs: text.split("\n\n").size, jargon: jargon)
    end

    def self.enforce(text)
      paragraphs = text.split(/\n{2,}/)
      if paragraphs.size > MAX_PARAGRAPHS
        paragraphs = paragraphs.first(MAX_PARAGRAPHS - 1) + [ paragraphs.drop(MAX_PARAGRAPHS - 1).join(" ") ]
      end
      truncate(paragraphs.join("\n\n"))
    end

    def self.clean(raw)
      text = raw.to_s.gsub(/\r\n?/, "\n")
      text = text.gsub(/^\s*```[a-z]*\s*$/i, "").delete("`")
      text = text.gsub(/^\s{0,3}\#{1,6}\s*/, "")
      text = text.gsub(/^\s*(?:[-*•]|\d+[.)])\s+/, "")
      text = text.gsub(/\*\*(.+?)\*\*/m, '\1').gsub(/__(.+?)__/m, '\1')
      text = text.gsub(/(?<![\w*])\*(?=\S)(.+?)(?<=\S)\*(?![\w*])/, '\1')
      text.split(/\n[ \t]*\n/).map { |paragraph| paragraph.gsub(/\s+/, " ").strip }.reject(&:empty?).join("\n\n")
    end

    def self.truncate(text)
      return text if text.length <= MAX_CHARS

      head = text[0, MAX_CHARS]
      boundary = head.rindex(/[.!?](?=\s|\z)/)
      return head[0..boundary] if boundary&.positive?

      "#{text[0, MAX_CHARS - 1].rstrip}…"
    end
    private_class_method :clean, :truncate
  end
end
