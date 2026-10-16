require "rails_helper"

RSpec.describe CageAssignment do
  let(:cage) { create(:cage, capacity: 3) }
  let(:rex) { create(:species, :carnivore, name: "Rex") }
  let(:raptor) { create(:species, :carnivore, name: "Raptor") }
  let(:trike) { create(:species, name: "Trike") }
  let(:steg) { create(:species, name: "Steg") }

  def assign(dinosaur, to: cage)
    described_class.call(dinosaur: dinosaur, cage_id: to.id)
  end

  def rejection(dinosaur, to: cage)
    assign(dinosaur, to: to)
    nil
  rescue ActiveRecord::RecordInvalid => e
    e.record.errors[:cage]
  end

  it "places a dinosaur in an empty cage" do
    dinosaur = create(:dinosaur, species: rex)
    assign(dinosaur)
    expect(dinosaur.reload.cage).to eq(cage)
  end

  it "lets carnivores of the same species share a cage" do
    create(:dinosaur, species: rex).tap { |d| assign(d) }
    expect(rejection(create(:dinosaur, species: rex))).to be_nil
  end

  it "rejects a carnivore of a different species" do
    create(:dinosaur, species: rex).tap { |d| assign(d) }
    expect(rejection(create(:dinosaur, species: raptor))).to be_present
  end

  it "rejects a carnivore in a cage with a herbivore" do
    create(:dinosaur, species: trike).tap { |d| assign(d) }
    expect(rejection(create(:dinosaur, species: rex))).to be_present
  end

  it "rejects a herbivore in a cage with a carnivore" do
    create(:dinosaur, species: rex).tap { |d| assign(d) }
    expect(rejection(create(:dinosaur, species: trike))).to be_present
  end

  it "lets different herbivore species share a cage" do
    create(:dinosaur, species: trike).tap { |d| assign(d) }
    expect(rejection(create(:dinosaur, species: steg))).to be_nil
  end

  it "rejects a dinosaur when the cage is full" do
    create_list(:dinosaur, 3, species: trike).each { |d| assign(d) }
    expect(rejection(create(:dinosaur, species: trike))).to include("is full")
  end

  it "rejects a dinosaur when the cage is powered down" do
    down = create(:cage, :down)
    expect(rejection(create(:dinosaur), to: down)).to include("is powered down")
  end

  it "rejects a cage that does not exist" do
    dinosaur = create(:dinosaur)
    expect { described_class.call(dinosaur: dinosaur, cage_id: 0) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(dinosaur.reload.cage).to be_nil
  end

  it "does not count the dinosaur itself against capacity when re-assigning to its own cage" do
    dinosaurs = create_list(:dinosaur, 3, species: trike)
    dinosaurs.each { |d| assign(d) }
    expect(rejection(dinosaurs.first)).to be_nil
  end

  it "leaves the dinosaur unplaced when a rule fails" do
    create_list(:dinosaur, 3, species: trike).each { |d| assign(d) }
    extra = create(:dinosaur, species: trike)
    rejection(extra)
    expect(extra.reload.cage).to be_nil
  end

  it "creates an unsaved dinosaur directly into the cage" do
    dinosaur = build(:dinosaur, species: rex)
    assign(dinosaur)
    expect(dinosaur).to be_persisted
    expect(dinosaur.reload.cage).to eq(cage)
  end

  it "does not save an unsaved dinosaur when a rule fails" do
    create_list(:dinosaur, 3, species: trike).each { |d| assign(d) }
    expect { rejection(build(:dinosaur, species: trike)) }.not_to change(Dinosaur, :count)
  end

  it "reports model validation errors before checking the cage" do
    dinosaur = build(:dinosaur, name: nil)
    expect { assign(dinosaur) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(dinosaur.errors.attribute_names).to eq([ :name ])
  end

  it "reports every broken rule at once" do
    full_down = create(:cage, :down, capacity: 1)
    create(:dinosaur, species: rex, cage: full_down)
    errors = rejection(create(:dinosaur, species: trike), to: full_down)
    expect(errors.size).to eq(3)
  end

  it "reports a missing species as a model error instead of failing" do
    dinosaur = build(:dinosaur, species: nil)
    expect { assign(dinosaur) }.to raise_error(ActiveRecord::RecordInvalid)
    expect(dinosaur.errors.attribute_names).to eq([ :species ])
  end
end
