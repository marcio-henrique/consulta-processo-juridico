require "rails_helper"

RSpec.describe "Query.lawsuit SQL query count", type: :graphql do
  let(:number) { "1001399-31.2023.8.26.0070" }
  let(:query) do
    <<~GQL
      query($number: String!, $first: Int) {
        lawsuit(number: $number) {
          errors { code }
          lawsuit {
            number forum court numberOfAuthors movementsCount
            value { amount formatted }
            movements(first: $first) {
              nodes { id date title content }
              pageInfo { hasNextPage endCursor }
            }
          }
        }
      }
    GQL
  end

  # Counts SQL statements issued by the block, ignoring schema lookups and
  # transaction control statements.
  def count_queries
    count = 0
    counter = lambda do |_name, _start, _finish, _id, payload|
      next if payload[:name] == "SCHEMA" || payload[:sql].match?(/\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/i)

      count += 1
    end
    ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
    count
  end

  it "runs a constant number of queries regardless of the page size (no N+1)" do
    lawsuit = create(:lawsuit, number: number)
    create_list(:movement, 40, lawsuit: lawsuit)

    user = create(:user) # created outside the counted blocks
    execute_graphql(query, variables: { number: number, first: 1 }, user: user) # warm up prepared statements

    small = count_queries { execute_graphql(query, variables: { number: number, first: 2 }, user: user) }
    large = count_queries { execute_graphql(query, variables: { number: number, first: 40 }, user: user) }

    # lawsuit lookup + movements page + movements count
    expect(small).to be <= 3
    expect(large).to eq(small)
  end
end
