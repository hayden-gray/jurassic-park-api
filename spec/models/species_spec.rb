require "rails_helper"

RSpec.describe Species, type: :model do
  it "is valid with a name and diet" do
    expect(build(:species)).to be_valid
  end

  it "requires a unique name" do
    create(:species, name: "Rex")
    expect(build(:species, name: "Rex")).not_to be_valid
  end

  it "rejects an unknown diet with a validation error" do
    species = build(:species, diet: "omnivore")
    expect(species).not_to be_valid
    expect(species.errors[:diet]).to be_present
  end

  it "rejects an invalid diet at the database" do
    species = create(:species)
    expect { species.update_column(:diet, "omnivore") }
      .to raise_error(ActiveRecord::StatementInvalid, /species_diet_valid/)
  end

  it "cannot be deleted while dinosaurs belong to it" do
    dinosaur = create(:dinosaur)
    expect(dinosaur.species.destroy).to be(false)
  end

  it "cannot change diet once created" do
    species = create(:species, diet: "herbivore")
    species.diet = "carnivore"
    expect(species).not_to be_valid
    expect(species.errors[:diet]).to include("can't be changed")
  end
end
