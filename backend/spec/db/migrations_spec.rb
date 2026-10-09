require "rails_helper"

# Proves the schema (already migrated by db:prepare in the test setup) has
# every table and constraint required by architecture.md section 3.
RSpec.describe "Database schema" do
  subject(:connection) { ActiveRecord::Base.connection }

  it "has the six domain tables" do
    expect(connection.tables).to include(
      "lawsuits", "movements", "summaries", "users", "sessions", "summary_feedbacks"
    )
  end

  it "enforces a unique index on lawsuits.number" do
    index = connection.indexes("lawsuits").find { |i| i.columns == [ "number" ] }
    expect(index.unique).to be true
  end

  it "enforces a case-insensitive unique index on users.email" do
    index = connection.indexes("users").find { |i| i.name == "index_users_on_lower_email" }
    expect(index.unique).to be true
    expect(index.columns).to match(/lower\(\(?email/)
  end

  it "enforces a unique index on sessions.token_digest" do
    index = connection.indexes("sessions").find { |i| i.columns == [ "token_digest" ] }
    expect(index.unique).to be true
  end

  it "enforces a unique composite index for the summary cache key" do
    index = connection.indexes("summaries").find { |i| i.name == "index_summaries_on_cache_key" }
    expect(index.unique).to be true
    expect(index.columns).to match_array(%w[lawsuit_id movements_digest prompt_version model])
  end

  it "enforces a unique composite index on summary_feedbacks (summary_id, user_id)" do
    index = connection.indexes("summary_feedbacks").find { |i| i.columns.sort == %w[summary_id user_id] }
    expect(index.unique).to be true
  end

  it "cascades delete from lawsuits to movements" do
    fk = connection.foreign_keys("movements").find { |f| f.to_table == "lawsuits" }
    expect(fk.on_delete).to eq(:cascade)
  end

  it "cascades delete from users to sessions" do
    fk = connection.foreign_keys("sessions").find { |f| f.to_table == "users" }
    expect(fk.on_delete).to eq(:cascade)
  end
end
