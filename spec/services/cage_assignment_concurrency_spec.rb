require "rails_helper"

RSpec.describe CageAssignment, "when two requests race for the last slot", type: :model do
  self.use_transactional_tests = false

  after { [Dinosaur, Cage, Species].each(&:delete_all) }

  it "places only one" do
    cage = create(:cage, capacity: 1)
    slow_save = ->(original) { sleep 0.2; original.call }

    threads = create_list(:dinosaur, 2).map do |dinosaur|
      allow(dinosaur).to receive(:save!).and_wrap_original(&slow_save)
      Thread.new { CageAssignment.call(dinosaur: dinosaur, cage_id: cage.id) rescue :rejected }
    end

    threads.each(&:join)

    expect(cage.dinosaurs.count).to eq(1)
  end
end
