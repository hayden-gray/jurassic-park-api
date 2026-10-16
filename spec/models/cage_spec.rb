require "rails_helper"

RSpec.describe Cage, type: :model do
  it "is valid with a positive capacity" do
    expect(build(:cage)).to be_valid
  end

  it "defaults to ACTIVE" do
    expect(Cage.new(capacity: 1)).to be_active
  end

  it "requires capacity" do
    expect(build(:cage, capacity: nil)).not_to be_valid
  end

  it "rejects zero or negative capacity" do
    expect(build(:cage, capacity: 0)).not_to be_valid
    expect(build(:cage, capacity: -1)).not_to be_valid
  end

  it "rejects non-integer capacity" do
    expect(build(:cage, capacity: 2.5)).not_to be_valid
  end

  it "rejects an unknown power status with a validation error" do
    cage = build(:cage, power_status: "BROKEN")
    expect(cage).not_to be_valid
    expect(cage.errors[:power_status]).to be_present
  end

  describe "database constraints" do
    it "rejects non-positive capacity" do
      expect { build(:cage, capacity: 0).save!(validate: false) }
        .to raise_error(ActiveRecord::StatementInvalid, /cages_capacity_positive/)
    end

    it "rejects an invalid power status" do
      cage = create(:cage)
      expect { cage.update_column(:power_status, "BROKEN") }
        .to raise_error(ActiveRecord::StatementInvalid, /cages_power_status_valid/)
    end
  end
end

RSpec.describe Cage, "occupancy rules", type: :model do
  let(:cage) { create(:cage, capacity: 3) }

  it "counts its dinosaurs" do
    create_list(:dinosaur, 2, cage: cage)
    expect(cage.dinosaur_count).to eq(2)
  end

  it "cannot be powered down while it contains dinosaurs" do
    create(:dinosaur, cage: cage)
    cage.power_status = "DOWN"
    expect(cage).not_to be_valid
  end

  it "can be powered down when empty and back up" do
    cage.update!(power_status: "DOWN")
    expect(cage.update(power_status: "ACTIVE")).to be(true)
  end

  it "cannot lower capacity below occupancy" do
    create_list(:dinosaur, 2, cage: cage)
    expect(cage.update(capacity: 1)).to be(false)
    expect(cage.update(capacity: 2)).to be(true)
  end

  it "cannot be destroyed while it contains dinosaurs" do
    create(:dinosaur, cage: cage)
    expect(cage.destroy).to be(false)
    expect(cage.errors[:base]).to be_present
  end
end
