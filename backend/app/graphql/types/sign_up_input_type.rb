module Types
  class SignUpInputType < Types::BaseInputObject
    graphql_name "SignUpInput"

    argument :email, String, required: true
    argument :password, String, required: true
  end
end
