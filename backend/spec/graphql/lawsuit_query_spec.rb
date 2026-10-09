require "rails_helper"

RSpec.describe "Query.lawsuit", type: :graphql do
  let(:number) { "1001399-31.2023.8.26.0070" }

  let(:query) do
    <<~GQL
      query Lawsuit($number: String!, $first: Int, $after: String) {
        lawsuit(number: $number) {
          errors { code message field }
          lawsuit {
            number forum court numberOfAuthors movementsCount
            value { amount formatted }
            movements(first: $first, after: $after) {
              nodes { id date title content }
              pageInfo { hasNextPage hasPreviousPage startCursor endCursor }
            }
          }
        }
      }
    GQL
  end

  def run(vars)
    execute_graphql(query, variables: vars)
  end

  describe "payload shapes" do
    before do
      create(:lawsuit, number: number, forum: "Foro de Batatais", court: "2ª Vara Cível",
        value: 10_000, number_of_authors: 1)
    end

    it "returns the lawsuit with an empty errors list" do
      payload = run(number: number).dig(:data, :lawsuit)

      expect(payload[:errors]).to eq([])
      expect(payload[:lawsuit]).to include(
        number: number,
        forum: "Foro de Batatais",
        court: "2ª Vara Cível",
        numberOfAuthors: 1,
        movementsCount: 0,
        value: { amount: "10000.00", formatted: "R$ 10.000,00" }
      )
    end

    it "accepts digits-only input and returns the canonical number" do
      payload = run(number: "10013993120238260070").dig(:data, :lawsuit)
      expect(payload[:lawsuit][:number]).to eq(number)
    end

    it "returns INVALID_CNJ with field number and no top-level error" do
      result = run(number: "1001399-31.2023.8.26.0071")

      expect(result[:errors]).to be_nil
      payload = result.dig(:data, :lawsuit)
      expect(payload[:lawsuit]).to be_nil
      expect(payload[:errors]).to eq([
        { code: "INVALID_CNJ", message: "Número de processo inválido. Confira os dígitos.", field: "number" }
      ])
    end

    it "returns NOT_FOUND for a valid number that is not stored" do
      result = run(number: "1002271-82.2025.8.26.0003")

      expect(result[:errors]).to be_nil
      payload = result.dig(:data, :lawsuit)
      expect(payload[:lawsuit]).to be_nil
      expect(payload[:errors]).to eq([
        { code: "NOT_FOUND", message: "Processo não encontrado na base.", field: nil }
      ])
    end
  end

  describe "movements" do
    let!(:lawsuit) { create(:lawsuit, number: number) }

    it "orders newest first and breaks same-date ties by ascending source_row" do
      create(:movement, lawsuit: lawsuit, occurred_on: "2024-06-10", title: "C", source_row: 5001)
      create(:movement, lawsuit: lawsuit, occurred_on: "2024-06-12", title: "A", source_row: 4997)
      create(:movement, lawsuit: lawsuit, occurred_on: "2024-06-10", title: "B", source_row: 5000)
      create(:movement, lawsuit: lawsuit, occurred_on: "2024-06-11", title: "Z", source_row: 4998, content: nil)
      create(:movement, lawsuit: lawsuit, occurred_on: "2024-06-10", title: "D", source_row: 4999, content: nil)

      nodes = run(number: number).dig(:data, :lawsuit, :lawsuit, :movements, :nodes)

      expect(nodes.map { |n| n[:title] }).to eq(%w[A Z D B C])
      expect(nodes.first[:date]).to eq("2024-06-12")
      expect(nodes.find { |n| n[:title] == "D" }[:content]).to be_nil
    end

    context "with 60 movements, several sharing a date" do
      before do
        60.times do |i|
          create(:movement, lawsuit: lawsuit, occurred_on: Date.new(2024, 1, 1) + (i / 4), source_row: i + 1,
            title: "M#{i + 1}")
        end
      end

      let(:expected_ids) { lawsuit.movements.display_order.pluck(:id).map(&:to_s) }

      def page(first:, after: nil)
        run(number: number, first: first, after: after).dig(:data, :lawsuit, :lawsuit)
      end

      it "defaults to 25 items" do
        movements = run(number: number).dig(:data, :lawsuit, :lawsuit, :movements)
        expect(movements[:nodes].size).to eq(25)
        expect(movements[:pageInfo][:hasNextPage]).to be(true)
        expect(movements[:pageInfo][:hasPreviousPage]).to be(false)
      end

      it "reports movementsCount independently of the page size" do
        expect(page(first: 3)[:movementsCount]).to eq(60)
      end

      it "traverses every page without duplicates or gaps" do
        collected = []
        cursor = nil
        loop do
          movements = page(first: 7, after: cursor)[:movements]
          collected.concat(movements[:nodes].map { |n| n[:id] })
          break unless movements[:pageInfo][:hasNextPage]

          cursor = movements[:pageInfo][:endCursor]
          expect(cursor).to be_present
        end

        expect(collected).to eq(expected_ids)
      end

      it "returns the last partial page with hasNextPage false" do
        cursor = page(first: 50)[:movements][:pageInfo][:endCursor]
        last = page(first: 50, after: cursor)[:movements]
        expect(last[:nodes].size).to eq(10)
        expect(last[:pageInfo][:hasNextPage]).to be(false)
      end

      it "accepts the maximum page size of 100" do
        expect(page(first: 100)[:movements][:nodes].size).to eq(60)
      end

      [ 0, -1, 101 ].each do |invalid|
        it "returns INVALID_ARGUMENT for first=#{invalid}" do
          result = run(number: number, first: invalid)

          expect(result[:errors]).to be_nil
          payload = result.dig(:data, :lawsuit)
          expect(payload[:errors]).to eq([
            { code: "INVALID_ARGUMENT", message: "Parâmetro inválido.", field: "first" }
          ])
          expect(payload[:lawsuit]).to be_nil
        end
      end

      it "returns INVALID_ARGUMENT for a malformed cursor" do
        payload = run(number: number, after: "not-a-cursor").dig(:data, :lawsuit)
        expect(payload[:errors].first).to include(code: "INVALID_ARGUMENT", field: "after")
      end
    end
  end
end
