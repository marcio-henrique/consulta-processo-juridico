require "rails_helper"

RSpec.describe Summaries::AmountCheck do
  let(:source) do
    <<~SOURCE
      Valor da causa: R$ 10.000,00
      23/04/2025 - Julgada Procedente em Parte a Ação: condenar a ré ao pagamento de danos morais no valor de R$ 8.000,00 (oito mil reais).
      10/05/2025 - Petição Juntada: honorários do conciliador (R$74,42) e custas de R$ 1.500,5.
    SOURCE
  end

  def offending(text)
    described_class.call(text, source)
  end

  it "accepts amounts that appear in the source" do
    text = "A causa vale R$ 10.000,00 e a condenação foi de R$ 8.000,00."

    expect(offending(text)).to be_empty
  end

  it "compares values, not spelling" do
    expect(offending("Foram pagos R$ 74,42 e R$ 8.000 e R$ 1.500,50.")).to be_empty
  end

  it "flags an amount with garbled separators" do
    expect(offending("A ré pagará R$ 8,000,00 por danos morais.")).to eq([ "8,000,00" ])
  end

  it "flags an amount that is not in the source" do
    expect(offending("A ré pagará R$ 9.000,00.")).to eq([ "9.000,00" ])
  end

  it "reports each offending amount once, as written" do
    expect(offending("Pagou R$ 9.000,00. Depois R$ 9.000,00 e ainda R$ 7.000,00.")).to eq([ "9.000,00", "7.000,00" ])
  end

  it "ignores a trailing sentence period or comma" do
    expect(offending("O valor foi de R$ 8.000,00. Depois, R$ 10.000,00, conforme a decisão.")).to be_empty
  end

  it "ignores numbers that are not amounts (dates, process numbers, counts)" do
    text = "O processo 1001399-31.2023.8.26.0070 começou em 12/05/2023 e tem 3 autores."

    expect(offending(text)).to be_empty
  end

  it "does not treat protocol-like source tokens as known amounts" do
    expect(described_class.call("Pagou R$ 23,00.", "Protocolo WBAT.23.70019358-0")).to eq([ "23,00" ])
  end

  it "returns an empty list for text without amounts" do
    expect(offending("Nada a declarar.")).to be_empty
  end
end
