class GraphqlController < ApplicationController
  # Request protection (spec 06, AU-5): POST only (routes.rb sends other verbs
  # to #method_not_allowed), JSON only, and same-origin when an Origin header
  # is present. SameSite=Lax cookies are the third layer against CSRF.
  before_action :verify_same_origin
  before_action :require_json_content_type, only: :execute

  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    session = Auth::Authenticate.call(cookies[Auth::SessionCookie::NAME])
    context = {
      current_user: session&.user,
      current_session: session,
      request_id: request.request_id,
      user_agent: request.user_agent,
      ip_address: request.remote_ip
    }

    result = BackendSchema.execute(
      query,
      variables: variables,
      context: context,
      operation_name: operation_name
    )
    apply_cookie_action(result.context[:cookie_action])

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

  # Mutations ask for cookie changes through the GraphQL context so that the
  # schema code never touches the HTTP layer.
  def apply_cookie_action(action)
    return if action.blank?

    if action[:set]
      cookies[Auth::SessionCookie::NAME] =
        Auth::SessionCookie.options(action[:set], expires_at: action[:expires_at])
    elsif action[:clear]
      cookies.delete(Auth::SessionCookie::NAME, path: "/")
    end
  end

  def verify_same_origin
    origin = request.headers["Origin"]
    return if origin.blank?
    return if origin_host(origin) == request.host

    render json: { errors: [ { message: "Origin not allowed" } ] }, status: :forbidden
  end

  def origin_host(origin)
    URI.parse(origin).host
  rescue URI::InvalidURIError
    nil
  end

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
