class BackendSchema < GraphQL::Schema
  query Types::QueryType

  # Query depth/complexity limits (security.md, architecture.md section 4).
  # Values are placeholders tightened in spec 03/SEC-3 once real fields exist.
  max_depth 15
  max_complexity 200
end
