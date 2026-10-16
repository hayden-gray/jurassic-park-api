class Cage < ApplicationRecord
  enum :power_status, { active: "ACTIVE", down: "DOWN" }, validate: true

  validates :capacity, numericality: { only_integer: true, greater_than: 0 }

  # Enums serialize their Ruby key ("active"); the API contract is the stored literal ("ACTIVE").
  def as_json(options = nil)
    super.merge("power_status" => self.class.power_statuses[power_status])
  end
end
