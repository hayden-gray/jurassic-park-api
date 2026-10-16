class Cage < ApplicationRecord
  has_many :dinosaurs, dependent: :restrict_with_error

  enum :power_status, { active: "ACTIVE", down: "DOWN" }, validate: true

  validates :capacity, numericality: { only_integer: true, greater_than: 0 }
  validate :not_powered_down_while_occupied, if: -> { down? && power_status_changed? }
  validate :capacity_covers_occupancy, if: -> { persisted? && capacity_changed? && capacity.to_i.positive? }

  def dinosaur_count
    dinosaurs.size
  end

  def as_json(options = nil)
    super.merge("power_status" => self.class.power_statuses[power_status], "dinosaur_count" => dinosaur_count)
  end

  private

  def not_powered_down_while_occupied
    errors.add(:power_status, "can't be DOWN while the cage contains dinosaurs") if dinosaurs.exists?
  end

  def capacity_covers_occupancy
    count = dinosaurs.count
    errors.add(:capacity, "can't be lower than the current number of dinosaurs (#{count})") if capacity < count
  end
end
