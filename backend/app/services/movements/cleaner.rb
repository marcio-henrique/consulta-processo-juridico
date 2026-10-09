module Movements
  # Reduces a movement's content to the text that matters for the summary
  # (docs/domains/ai-summary.md section 2.2):
  #
  # - keeps only what follows "Teor do ato:" (the court's decision text);
  # - removes lawyer lines (names and OAB numbers are PII) and publication
  #   boilerplate lines;
  # - drops the standard notice to lawyers ("Sr(a). Advogado(a): ...");
  # - normalizes whitespace without changing words.
  class Cleaner
    TEOR_MARKER = /Teor do ato:/i
    REMOVED_LINE = /\A\s*(?:Advogados?\(s\):|N[º°o] Protocolo:|Rela[çc][ãa]o:|Data da Publica[çc][ãa]o:|N[úu]mero do Di[áa]rio:|Tipo de publica[çc][ãa]o:|N[úu]mero do Di[áa]rio Eletr[ôo]nico:)/i
    LAWYER_NOTICE = /\s*Sr\(a\)\.\s*Advogado\(a\):.*\z/m

    def self.call(content)
      new(content).call
    end

    # True when the content carries the court's text ("Teor do ato:").
    def self.teor?(content)
      content.to_s.match?(TEOR_MARKER)
    end

    def initialize(content)
      @content = content.to_s
    end

    def call
      text = @content.split(TEOR_MARKER, 2).last.to_s
      lines = text.lines.reject { |line| line.match?(REMOVED_LINE) }
      lines.join(" ").sub(LAWYER_NOTICE, "").gsub(/\s+/, " ").strip
    end
  end
end
