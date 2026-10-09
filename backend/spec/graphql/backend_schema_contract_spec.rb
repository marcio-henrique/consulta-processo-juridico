require "rails_helper"

# Proves the schema implements every field declared in the contract
# (docs/contracts/schema.graphql), per F-10's acceptance criteria. This is a
# structural check, not a behavior check: resolver bodies are stubs until
# their owning spec lands.
RSpec.describe "BackendSchema contract coverage" do
  def field_names(graphql_type)
    graphql_type.fields.keys
  end

  it "defines every Query field from the contract" do
    expect(field_names(BackendSchema.query)).to include("me", "lawsuit")
  end

  it "defines every Mutation field from the contract" do
    expect(field_names(BackendSchema.mutation)).to include(
      "signUp", "signIn", "signOut", "generateSummary", "rateSummary"
    )
  end

  it "defines the Lawsuit type with every contract field" do
    lawsuit_type = BackendSchema.types["Lawsuit"]

    expect(field_names(lawsuit_type)).to include(
      "number", "forum", "court", "value", "numberOfAuthors",
      "movementsCount", "movements", "latestSummary"
    )
  end

  it "defines the Movement, Summary, UserError and Money types" do
    expect(field_names(BackendSchema.types["Movement"])).to include("id", "date", "title", "content")
    expect(field_names(BackendSchema.types["Summary"])).to include("id", "body", "generatedAt", "myFeedback")
    expect(field_names(BackendSchema.types["UserError"])).to include("code", "message", "field")
    expect(field_names(BackendSchema.types["Money"])).to include("amount", "formatted")
  end

  it "defines the ErrorCode enum with every contract value" do
    expect(BackendSchema.types["ErrorCode"].values.keys).to contain_exactly(
      "INVALID_CNJ", "NOT_FOUND", "INVALID_ARGUMENT", "UNAUTHENTICATED",
      "SUMMARY_UNAVAILABLE", "RATE_LIMITED", "VALIDATION_FAILED"
    )
  end

  it "dumps a schema definition without raising" do
    expect { BackendSchema.to_definition }.not_to raise_error
  end
end
