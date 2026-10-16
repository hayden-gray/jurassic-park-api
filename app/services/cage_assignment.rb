class CageAssignment
  def self.call(dinosaur:, cage_id:)
    new(dinosaur, cage_id).call
  end

  def initialize(dinosaur, cage_id)
    @dinosaur = dinosaur
    @cage_id = cage_id
  end

  def call
    Dinosaur.transaction do
      # Lock the cage row so concurrent requests for the same cage run one at a time.
      @cage = Cage.lock.find_by(id: cage_id)
      raise_if_any(failures)

      dinosaur.cage = cage
      dinosaur.save!
    end
  end

  private

  attr_reader :dinosaur, :cage_id, :cage

  def failures
    return [ "must exist" ] unless cage

    failures = []
    failures << "is powered down" if cage.down?
    failures << "is full" if others.size >= cage.capacity
    failures << "holds other species; carnivores can only share a cage with their own species" if carnivore_conflict?
    failures << "holds carnivores; herbivores cannot share a cage with them" if herbivore_conflict?
    failures
  end

  def others
    @others ||= cage.dinosaurs.where.not(id: dinosaur.id).includes(:species).to_a
  end

  def carnivore_conflict?
    dinosaur.species&.carnivore? && others.any? { |other| other.species_id != dinosaur.species_id }
  end

  def herbivore_conflict?
    dinosaur.species&.herbivore? && others.any? { |other| other.species.carnivore? }
  end

  def raise_if_any(failures)
    return if failures.empty?

    failures.each { |failure| dinosaur.errors.add(:cage, failure) }
    raise ActiveRecord::RecordInvalid, dinosaur
  end
end
