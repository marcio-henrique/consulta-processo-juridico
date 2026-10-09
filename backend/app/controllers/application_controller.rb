class ApplicationController < ActionController::API
  # API mode ships without cookie support; the session cookie needs it.
  include ActionController::Cookies
end
