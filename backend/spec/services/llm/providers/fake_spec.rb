require "rails_helper"

RSpec.describe Llm::Providers::Fake do
  let(:user_prompt) do
    <<~PROMPT
      Dados do processo:
      Número do processo: 1001399-31.2023.8.26.0070
      Foro: Foro de Batatais
      Vara: 2ª Vara Cível
      Valor da causa: R$ 10.000,00
      Número de autores: 1
      Primeira movimentação: 10/05/2023
      Última movimentação: 12/06/2024
    PROMPT
  end

  def complete(provider, user: user_prompt)
    provider.complete(model: "fake-v1", system: "sys", user: user, max_output_tokens: 700, timeout: 20)
  end

  it "builds a deterministic 3-paragraph pt-BR summary from the prompt metadata" do
    provider = described_class.new
    first = complete(provider)
    second = complete(provider)

    expect(first.text).to eq(second.text)
    expect(first.text.split(/\n{2,}/).size).to eq(3)
    expect(first.text).to include("1001399-31.2023.8.26.0070", "2ª Vara Cível", "Foro de Batatais",
      "R$ 10.000,00", "12/06/2024")
    expect(first.text).not_to match(/[#*`]/)
  end

  it "reports not-informed placeholders when the prompt has no metadata" do
    text = complete(described_class.new, user: "nada").text

    expect(text).to include("não informado")
  end

  it "returns an Llm::Result with estimated token counts and the fake model" do
    result = complete(described_class.new)

    expect(result).to have_attributes(model: "fake-v1")
    expect(result.input_tokens).to be > 0
    expect(result.output_tokens).to be > 0
  end

  it "raises the scripted failures in order, then succeeds" do
    provider = described_class.new(failures: [ Llm::TimeoutError.new, Llm::ProviderError.new("boom") ])

    expect { complete(provider) }.to raise_error(Llm::TimeoutError)
    expect { complete(provider) }.to raise_error(Llm::ProviderError, "boom")
    expect(complete(provider).text).to be_present
    expect(provider.calls.size).to eq(3)
  end

  it "can return a scripted text, one per call, repeating the last" do
    provider = described_class.new(texts: [ "primeiro", "segundo" ])

    expect(3.times.map { complete(provider).text }).to eq(%w[primeiro segundo segundo])
  end

  it "counts calls safely across threads" do
    provider = described_class.new
    10.times.map { Thread.new { complete(provider) } }.each(&:join)

    expect(provider.calls.size).to eq(10)
  end

  it "records the prompts it received" do
    provider = described_class.new
    complete(provider)

    expect(provider.calls.first).to include(model: "fake-v1", system: "sys", max_output_tokens: 700)
  end
end
