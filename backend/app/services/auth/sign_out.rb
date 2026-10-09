module Auth
  class SignOut
    def self.call(session)
      session&.destroy
    end
  end
end
