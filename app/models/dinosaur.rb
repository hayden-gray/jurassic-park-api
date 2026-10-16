class Dinosaur < ApplicationRecord
  belongs_to :species
  belongs_to :cage, optional: true

  validates :name, presence: true
  validate :species_cannot_change, on: :update

  def as_json(options = nil)
    super(only: %i[id name species_id cage_id created_at updated_at])
      .merge("species" => species.name, "diet" => species.diet)
  end

  private

  def species_cannot_change
    errors.add(:species_id, "can't be changed") if species_id_changed?
  end
end
