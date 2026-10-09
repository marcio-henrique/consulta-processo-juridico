module Mutations
  # Shared by the auth mutations: turns a service result into the AuthPayload
  # hash and asks the controller (through the context) to set the cookie.
  module AuthSupport
    module_function

    def payload(result)
      { user: result.user, errors: result.errors }
    end

    # Replaces the current session (if any) with the new one so sessions do
    # not pile up when a signed-in user signs in or up again.
    def start_session(result, context)
      Auth::SignOut.call(context[:current_session])
      context[:current_user] = result.user
      context[:current_session] = result.session
      context[:cookie_action] = { set: result.token, expires_at: result.session.expires_at }
    end
  end
end
