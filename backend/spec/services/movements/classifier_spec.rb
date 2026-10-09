require "rails_helper"

RSpec.describe Movements::Classifier do
  describe "fixture of real titles (spec/fixtures/classifier_titles.yml)" do
    entries = YAML.load_file(Rails.root.join("spec/fixtures/classifier_titles.yml"))

    entries.each do |entry|
      it "classifies #{entry['title'].inspect} as #{entry['expected']}" do
        expect(described_class.call(entry["title"])).to eq(entry["expected"].to_sym)
      end
    end
  end

  describe "matching" do
    it "ignores case, accents and repeated spaces" do
      expect(described_class.call("RECEBIDA A PETICAO INICIAL  - Citação Por Carta AR")).to eq(:milestone)
      expect(described_class.call("  remetido   ao dje ")).to eq(:noise)
    end

    it "anchors rules at the start so embedded phrases do not match" do
      title = "Transmitida a decisão monocrática à vara de origem (Expedido Certidão)"

      expect(described_class.call(title)).to eq(:context)
    end

    it "separates the bare and the parenthesized 'Conclusos para o Relator'" do
      expect(described_class.call("Conclusos para o Relator")).to eq(:context)
      expect(described_class.call("Conclusos para o Relator (Expedido Termo com Conclusão)")).to eq(:noise)
    end

    it "classifies every Processamento de Grupos e Câmaras variant as noise" do
      title = "Processo encaminhado para o Processamento de Grupos e Câmaras para Intimação do Acórdão - Julgamento Virtual"

      expect(described_class.call(title)).to eq(:noise)
    end

    it "treats appeal outcomes and urgent-relief decisions as milestones" do
      [ "Provimento em Parte", "Não-Provimento", "Concedida a Antecipação de tutela",
        "Não Concedida a Medida Liminar", "Indeferida a Petição Inicial sem Resolução do Mérito" ].each do |title|
        expect(described_class.call(title)).to eq(:milestone), title
      end
    end

    it "defaults unknown titles to context" do
      expect(described_class.call("Um título que nunca vimos")).to eq(:context)
    end

    it "defaults blank titles to context" do
      expect(described_class.call(nil)).to eq(:context)
      expect(described_class.call("")).to eq(:context)
    end

    it "returns the first matching class (rule order)" do
      # 'Pedido de Extinção ...' is a milestone; no earlier noise rule may steal it.
      expect(described_class.call("Pedido de Extinção Juntada")).to eq(:milestone)
    end
  end

  describe "Teor do ato promotion" do
    it "promotes a noise movement to milestone when the content has the court's text" do
      content = "Relação: 0914/2023\nTeor do ato: Homologo o acordo.\nAdvogados(s): X (OAB 1/SP)"

      expect(described_class.call("Remetido ao DJE", content: content)).to eq(:milestone)
    end

    it "keeps noise when the content has no Teor do ato" do
      expect(described_class.call("Remetido ao DJE", content: "Relação: 0914/2023")).to eq(:noise)
    end

    it "keeps the title class when no content is given" do
      expect(described_class.call("Remetido ao DJE", content: nil)).to eq(:noise)
    end
  end
end
