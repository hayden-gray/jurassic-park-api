FactoryBot.define do
  factory :cage do
    capacity { 4 }
    power_status { "ACTIVE" }

    trait :down do
      power_status { "DOWN" }
    end
  end
end
