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
