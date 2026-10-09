# Authorization guard (spec 06, requirement 4.1): every root Query/Mutation
# field except the allow-list returns UNAUTHENTICATED to anonymous callers
# without running the resolver. The allow-list is explicit and tested by
# spec/graphql/guard_spec.rb, which iterates the whole schema.
module Guard
  ALLOW_LIST = %w[signUp signIn me].freeze

  module_function

  def protected_field?(field)
    root_types.include?(field.owner) && !ALLOW_LIST.include?(field.graphql_name)
  end

  def reject?(field, context)
    protected_field?(field) && context[:current_user].nil?
  end

  # Fits every payload type of the contract ({ ..., errors: [UserError!]! }).
  def unauthenticated_payload
    {
      success: false,
      errors: [ Errors::Messages.build("UNAUTHENTICATED", Errors::Messages::UNAUTHENTICATED) ]
    }
  end

  def root_types
    [ Types::QueryType, Types::MutationType ]
  end
end
