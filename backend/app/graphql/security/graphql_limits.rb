module Security
  # GraphQL hardening applied to the schema (SEC-3; docs/security.md S8):
  # alias limit, and no introspection entry points in production. Depth,
  # complexity and page size limits live next to their definitions
  # (BackendSchema, Lawsuits::MovementsPage).
  module GraphqlLimits
    module_function

    def apply(schema, rails_env: Rails.env)
      schema.query_analyzer(Security::AliasLimit)
      schema.disable_introspection_entry_points if rails_env.production?
      schema
    end
  end
end
