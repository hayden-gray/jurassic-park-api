# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Species required by the spec. Idempotent: safe to run repeatedly.
{
  "carnivore" => %w[Tyrannosaurus Velociraptor Spinosaurus Megalosaurus],
  "herbivore" => %w[Brachiosaurus Stegosaurus Ankylosaurus Triceratops]
}.each do |diet, names|
  names.each { |name| Species.find_or_create_by!(name: name) { |s| s.diet = diet } }
end
