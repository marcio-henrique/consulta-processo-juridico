class BackendSchema < GraphQL::Schema
  query Types::QueryType
  mutation Types::MutationType

  use GraphQL::Dataloader

  # Query limits (security.md, architecture.md section 4).
  max_depth 10
  max_complexity 200
  Security::GraphqlLimits.apply(self)

  GENERIC_ERROR_MESSAGE = "Erro interno. Tente novamente.".freeze

  # Unexpected exceptions: log class, message and request id (never params or
  # movement contents) and return a generic message. Expected failures are
  # returned as UserError data by the resolvers, not raised.
  rescue_from(StandardError) do |error, _obj, _args, ctx, _field|
    request_id = ctx[:request_id]
    Rails.logger.error(
      "GraphQL unexpected error: #{error.class}: #{error.message} request_id=#{request_id || '-'}"
    )
    raise GraphQL::ExecutionError, GENERIC_ERROR_MESSAGE
  end
end
