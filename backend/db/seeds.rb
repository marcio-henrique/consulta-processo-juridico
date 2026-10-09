# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Import the challenge CSV on an empty database. Idempotent: skipped when
# lawsuits already exist. A missing/invalid file raises Imports::FatalError and
# fails the command.
if Lawsuit.none?
  puts Imports::LawsuitsCsv.call
else
  puts "Lawsuits already imported (#{Lawsuit.count}); skipping CSV import."
end
