module Security
  # Rejects queries that repeat one field under more than MAX_ALIASES aliases
  # (alias flooding multiplies work in a single request, for example
  # many signIn attempts or many lawsuit lookups).
  class AliasLimit < GraphQL::Analysis::Analyzer
    MAX_ALIASES = 20

    def initialize(query_or_multiplex)
      super
      @counts = Hash.new(0)
    end

    def on_enter_field(node, _parent, visitor)
      return if node.alias.nil?

      @counts[[ visitor.parent_type_definition.graphql_name, node.name ]] += 1
    end

    def result
      return unless @counts.values.any? { |count| count > MAX_ALIASES }

      GraphQL::AnalysisError.new("Too many aliases of the same field (maximum #{MAX_ALIASES}).")
    end
  end
end
