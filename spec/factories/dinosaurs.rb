FactoryBot.define do
  factory :dinosaur do
    sequence(:name) { |n| "Dino #{n}" }
    species
  end
end
