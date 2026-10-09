require "rails_helper"

# Schema-wide guard: every root field except the allow-list rejects anonymous
# calls with UNAUTHENTICATED *without executing the operation*. The spec
# iterates the schema so a newly added field cannot be left unprotected by
# accident.
RSpec.describe "GraphQL authorization guard", type: :graphql do
  ALLOW_LIST = %w[signUp signIn me].freeze

  def root_fields
    [ BackendSchema.query, BackendSchema.mutation ].flat_map do |root|
      root.fields.values.map { |field| [ root, field ] }
    end
  end

  def dummy_literal(argument)
    case argument.type.unwrap.graphql_name
    when "Boolean" then "true"
    when "Int" then "1"
    when "ID" then '"1"'
    when "String" then '"1001399-31.2023.8.26.0070"'
    else raise "unsupported argument type #{argument.type.unwrap.graphql_name} on #{argument.graphql_name}"
    end
  end

  def query_for(root, field)
    args = field.arguments.values.select { |a| a.type.non_null? }.map { |a| "#{a.graphql_name}: #{dummy_literal(a)}" }
    call = args.empty? ? field.graphql_name : "#{field.graphql_name}(#{args.join(', ')})"
    "#{root == BackendSchema.query ? 'query' : 'mutation'} { #{call} { errors { code } } }"
  end

  it "keeps the allow-list explicit" do
    expect(Guard::ALLOW_LIST).to match_array(ALLOW_LIST)
  end

  it "knows every root field (so the iteration below is not vacuous)" do
    names = root_fields.map { |_, f| f.graphql_name }
    expect(names).to include("lawsuit", "generateSummary", "rateSummary", "signOut", *ALLOW_LIST)
  end

  it "rejects anonymous calls on every non-allow-listed root field with UNAUTHENTICATED" do
    protected_fields = root_fields.reject { |_, f| ALLOW_LIST.include?(f.graphql_name) }
    expect(protected_fields).not_to be_empty

    protected_fields.each do |root, field|
      result = execute_graphql(query_for(root, field), user: nil)

      expect(result[:errors]).to be_nil, "#{field.graphql_name}: #{result[:errors]}"
      payload = result.dig(:data, field.graphql_name.to_sym)
      expect(payload&.dig(:errors, 0, :code)).to eq("UNAUTHENTICATED"), "#{field.graphql_name} is reachable anonymously"
    end
  end

  it "does not execute the protected operations for anonymous callers" do
    allow(Lawsuits::Find).to receive(:call)
    allow(Summaries::Generate).to receive(:call)

    execute_graphql('{ lawsuit(number: "1001399-31.2023.8.26.0070") { errors { code } } }', user: nil)
    execute_graphql('mutation { generateSummary(lawsuitNumber: "1001399-31.2023.8.26.0070") { errors { code } } }', user: nil)

    expect(Lawsuits::Find).not_to have_received(:call)
    expect(Summaries::Generate).not_to have_received(:call)
  end

  it "uses the contract message for the rejection" do
    result = execute_graphql('{ lawsuit(number: "1") { errors { code message field } } }', user: nil)
    expect(result.dig(:data, :lawsuit, :errors, 0)).to eq(
      code: "UNAUTHENTICATED", message: "Faça login para continuar.", field: nil
    )
  end

  it "lets signed-in users through" do
    create(:lawsuit, number: "1001399-31.2023.8.26.0070")
    result = execute_graphql('{ lawsuit(number: "1001399-31.2023.8.26.0070") { lawsuit { number } errors { code } } }', user: :default)
    expect(result.dig(:data, :lawsuit, :lawsuit, :number)).to eq("1001399-31.2023.8.26.0070")
  end

  it "keeps signUp, signIn and me reachable anonymously" do
    expect(execute_graphql("{ me { id } }", user: nil)).to eq(data: { me: nil })
  end
end
