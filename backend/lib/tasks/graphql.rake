namespace :graphql do
  namespace :schema do
    desc "Dump the GraphQL schema to backend/schema.graphql (used by frontend codegen and CI drift check)"
    task dump: :environment do
      path = Rails.root.join("schema.graphql")
      File.write(path, BackendSchema.to_definition)
      puts "Wrote #{path}"
    end

    desc "Compare BackendSchema against docs/contracts/schema.graphql (see bin/contract_check)"
    task check: :environment do
      system(Rails.root.join("bin/contract_check").to_s, exception: true)
    end
  end
end
