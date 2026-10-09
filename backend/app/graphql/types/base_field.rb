module Types
  class BaseField < GraphQL::Schema::Field
    # Runs the authorization guard before any root field resolver.
    def resolve(object, args, query_ctx)
      return Guard.unauthenticated_payload if Guard.reject?(self, query_ctx)

      super
    end
  end
end
