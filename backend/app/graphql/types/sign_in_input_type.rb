module Types
  class SignInInputType < Types::BaseInputObject
    graphql_name "SignInInput"

    argument :email, String, required: true
    argument :password, String, required: true
  end
end
