require "rails_helper"

RSpec.describe Summaries::OutputValidator do
  describe ".call" do
    it "returns the text and the paragraph count for a clean answer" do
      output = described_class.call("Primeiro parágrafo.\n\nSegundo parágrafo.")

      expect(output.text).to eq("Primeiro parágrafo.\n\nSegundo parágrafo.")
      expect(output.paragraphs).to eq(2)
      expect(output).to be_within_limits
      expect(output.jargon).to be_empty
    end

    it "rejects blank output as a provider error" do
      [ nil, "", "   \n\n  ", "```\n```", "##" ].each do |blank|
        expect { described_class.call(blank) }.to raise_error(Llm::ProviderError, /empty/i)
      end
    end

    describe "markdown stripping" do
      it "removes headings" do
        expect(described_class.call("## Resumo\n\nO processo começou.").text).to eq("Resumo\n\nO processo começou.")
      end

      it "removes list markers (bullets and numbers)" do
        text = "Etapas:\n- pedido feito\n* defesa\n• decisão\n1. recurso\n2) arquivamento"

        expect(described_class.call(text).text).to eq("Etapas: pedido feito defesa decisão recurso arquivamento")
      end

      it "removes bold, italic and backticks but keeps the words" do
        text = "O **juiz** decidiu *a favor* do __autor__ no `processo`."

        expect(described_class.call(text).text).to eq("O juiz decidiu a favor do autor no processo.")
      end

      it "removes code fences" do
        expect(described_class.call("```\nTexto simples.\n```").text).to eq("Texto simples.")
      end

      it "keeps underscores inside words and asterisks used as footnote-free text intact" do
        expect(described_class.call("Número do_processo e 3 * 4.").text).to eq("Número do_processo e 3 * 4.")
      end
    end

    describe "paragraphs" do
      it "joins single line breaks inside a paragraph and normalizes spaces" do
        expect(described_class.call("Linha um\ncontinua   aqui.\r\n\r\n\r\nOutro.").text)
          .to eq("Linha um continua aqui.\n\nOutro.")
      end

      it "counts paragraphs and flags more than three" do
        output = described_class.call("A.\n\nB.\n\nC.\n\nD.")

        expect(output.paragraphs).to eq(4)
        expect(output).not_to be_within_limits
      end

      it "flags more than 2,000 characters" do
        output = described_class.call("Frase longa. " * 200)

        expect(output).not_to be_within_limits
      end
    end

    describe "jargon blocklist" do
      it "reports blocklisted terms and logs a warning without blocking" do
        log = StringIO.new
        original = Rails.logger
        Rails.logger = Logger.new(log)

        output = described_class.call("O juiz decidiu data venia que o ato foi Ad Cautelam.")

        expect(output.text).to be_present
        expect(output.jargon).to contain_exactly("data venia", "ad cautelam")
        expect(log.string).to include("WARN").and include("data venia")
        expect(log.string).not_to include("O juiz decidiu")
      ensure
        Rails.logger = original
      end

      it "does not match inside other words" do
        expect(described_class.call("Houve um ex viagem de trabalho.").jargon).to be_empty
      end
    end
  end

  describe ".enforce" do
    it "returns text within limits untouched" do
      text = "A.\n\nB.\n\nC."

      expect(described_class.enforce(text)).to eq(text)
    end

    it "merges the extra paragraphs into the third" do
      expect(described_class.enforce("A.\n\nB.\n\nC.\n\nD.\n\nE.")).to eq("A.\n\nB.\n\nC. D. E.")
    end

    it "truncates at a sentence boundary under 2,000 characters" do
      text = (1..400).map { |i| "Frase número #{i}." }.join(" ")

      result = described_class.enforce(text)

      expect(result.length).to be <= 2_000
      expect(result).to end_with(".")
      expect(result).to match(/Frase número \d+\.\z/)
    end

    it "truncates with an ellipsis when there is no sentence boundary" do
      result = described_class.enforce("palavra " * 500)

      expect(result.length).to be <= 2_000
      expect(result).to end_with("…")
    end

    it "applies both rules together" do
      long_paragraph = (1..120).map { |i| "Sentença #{i}." }.join(" ")
      text = ([ "Um." ] + Array.new(4) { long_paragraph }).join("\n\n")

      result = described_class.enforce(text)

      expect(result.length).to be <= 2_000
      expect(result.split(/\n{2,}/).size).to be <= 3
    end
  end
end
