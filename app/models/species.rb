class Species < ApplicationRecord
  has_many :dinosaurs, dependent: :restrict_with_error

  enum :diet, { herbivore: "herbivore", carnivore: "carnivore" }, validate: true

  validates :name, presence: true, uniqueness: true
end
