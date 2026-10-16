require "rails_helper"

RSpec.describe Dinosaur, type: :model do
  it "is valid with a name and species" do
    expect(build(:dinosaur)).to be_valid
  end

  it "requires a name" do
    expect(build(:dinosaur, name: nil)).not_to be_valid
    expect(build(:dinosaur, name: "  ")).not_to be_valid
  end

  it "requires a species" do
    expect(build(:dinosaur, species: nil)).not_to be_valid
  end

  it "does not require a cage" do
    expect(build(:dinosaur, cage: nil)).to be_valid
  end

  it "allows duplicate names" do
    create(:dinosaur, name: "Rex")
    expect(build(:dinosaur, name: "Rex")).to be_valid
  end

  it "rejects a blank name at the database" do
    expect { build(:dinosaur, name: " ").save!(validate: false) }
      .to raise_error(ActiveRecord::StatementInvalid, /dinosaurs_name_not_blank/)
  end

  it "includes the species name and diet in JSON" do
    dinosaur = create(:dinosaur, species: create(:species, :carnivore, name: "Velociraptor"))
    expect(dinosaur.as_json).to include("species" => "Velociraptor", "diet" => "carnivore")
  end
end
