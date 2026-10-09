require "rails_helper"

RSpec.describe Movements::Cleaner do
  let(:publication) do
    <<~TEXT.chomp
      Relação: 0914/2023
      Data da Publicação: 06/12/2023
      Número do Diário: 3872
    TEXT
  end

  let(:decision) do
    <<~TEXT.chomp
      Relação: 0914/2023
      Teor do ato: Diante do exposto, homologo o acordo.   Custas conforme o ajuste.
      Advogados(s): Fulano de Tal (OAB 288477/SP), Beltrano (OAB 354990/SP)
    TEXT
  end

  describe ".call" do
    it "keeps only the text after 'Teor do ato:'" do
      expect(described_class.call(decision)).to eq("Diante do exposto, homologo o acordo. Custas conforme o ajuste.")
    end

    it "removes lawyer lines in both spellings" do
      text = "Advogados(s): A (OAB 1/SP)\nMantida a decisão.\nAdvogado(s): B (OAB 2/SP)"

      expect(described_class.call(text)).to eq("Mantida a decisão.")
    end

    it "removes publication boilerplate lines and nothing else" do
      text = <<~TEXT.chomp
        #{publication}
        Tipo de publicação: Intimação
        Número do Diário Eletrônico: 3872
        Intimado para se manifestar em cinco dias.
      TEXT

      expect(described_class.call(text)).to eq("Intimado para se manifestar em cinco dias.")
    end

    it "removes the electronic filing protocol line but keeps the petition type" do
      text = "Nº Protocolo: WBAT.23.70019358-0\nTipo da Petição: Contestação\nData: 25/08/2023 17:39"

      expect(described_class.call(text)).to eq("Tipo da Petição: Contestação Data: 25/08/2023 17:39")
    end

    it "returns an empty string for pure boilerplate" do
      expect(described_class.call(publication)).to eq("")
    end

    it "returns an empty string for nil or blank content" do
      expect(described_class.call(nil)).to eq("")
      expect(described_class.call("  \n ")).to eq("")
    end

    it "normalizes whitespace without changing words" do
      expect(described_class.call("  Foi\t\tjuntada  a\n\n petição   inicial.  ")).to eq("Foi juntada a petição inicial.")
    end

    it "drops the notice to lawyers appended to some decisions" do
      text = "Teor do ato: Vistos. Manifeste-se a autora. Intime-se. Sr(a). Advogado(a): Ao realizar o peticionamento, utilize o código."

      expect(described_class.call(text)).to eq("Vistos. Manifeste-se a autora. Intime-se.")
    end

    it "keeps a Teor do ato body that spans several lines" do
      text = "Teor do ato: Primeira linha.\nSegunda linha.\nAdvogados(s): X (OAB 9/SP)"

      expect(described_class.call(text)).to eq("Primeira linha. Segunda linha.")
    end

    it "never leaves OAB numbers from a lawyer line" do
      expect(described_class.call(decision)).not_to match(/OAB|Advogad/)
    end
  end

  describe ".teor?" do
    it "detects the marker" do
      expect(described_class.teor?(decision)).to be(true)
      expect(described_class.teor?(publication)).to be(false)
      expect(described_class.teor?(nil)).to be(false)
    end
  end
end
