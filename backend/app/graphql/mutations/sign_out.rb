module Mutations
  # Mutation.signOut: deletes the session row and asks the controller to
  # clear the cookie. Protected by the guard (anonymous callers never get here).
  class SignOut
    def self.call(context:)
      Auth::SignOut.call(context[:current_session])
      context[:current_user] = nil
      context[:current_session] = nil
      context[:cookie_action] = { clear: true }
      { success: true, errors: [] }
    end
  end
end
