class Dinosaur < ApplicationRecord
  belongs_to :species
  belongs_to :cage, optional: true

  validates :name, presence: true

  def as_json(options = nil)
    super(only: %i[id name species_id cage_id created_at updated_at])
      .merge("species" => species.name, "diet" => species.diet)
  end
end
