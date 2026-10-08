namespace :graphql do
  namespace :schema do
    desc "Dump the GraphQL schema to backend/schema.graphql (used by frontend codegen and CI drift check)"
    task dump: :environment do
      path = Rails.root.join("schema.graphql")
      File.write(path, BackendSchema.to_definition)
      puts "Wrote #{path}"
    end
  end
end
