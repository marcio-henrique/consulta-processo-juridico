class GraphqlController < ApplicationController
  # Only accept POST (routes.rb already restricts the verb; Rails returns a
  # routing error -> 404 for other verbs by default, so method_not_allowed
  # is raised explicitly here isn't needed). Content type is enforced below.
  before_action :require_json_content_type, only: :execute

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = { current_user: nil, request_id: request.request_id }

    result = BackendSchema.execute(
      query,
      variables: variables,
      context: context,
      operation_name: operation_name
    )

    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?

    handle_error_in_development(e)
  end

  def method_not_allowed
    render json: { errors: [ { message: "Only POST is supported" } ] },
      status: :method_not_allowed
  end

  private

  def require_json_content_type
    return if request.content_type.to_s.start_with?("application/json")

    render json: { errors: [ { message: "Content-Type must be application/json" } ] },
      status: :unsupported_media_type
  end

  # Handle variables in form data, JSON body, or a blank value
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace.join("\n")

    render json: { errors: [ { message: e.message, backtrace: e.backtrace } ], data: {} },
      status: :internal_server_error
  end
end
