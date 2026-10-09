module Resolvers
  # Query.me: the signed-in user or null (allow-listed in Guard).
  class MeResolver
    def self.call(context:)
      context[:current_user]
    end
  end
end
