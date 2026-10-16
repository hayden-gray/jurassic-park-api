class Species < ApplicationRecord
  has_many :dinosaurs, dependent: :restrict_with_error

  enum :diet, { herbivore: "herbivore", carnivore: "carnivore" }, validate: true

  validates :name, presence: true, uniqueness: true
  validate :diet_cannot_change, on: :update

  private

  def diet_cannot_change
    errors.add(:diet, "can't be changed") if diet_changed?
  end
end
