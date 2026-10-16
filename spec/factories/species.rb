FactoryBot.define do
  factory :species do
    sequence(:name) { |n| "Species #{n}" }
    diet { "herbivore" }

    trait :carnivore do
      diet { "carnivore" }
    end
  end
end
