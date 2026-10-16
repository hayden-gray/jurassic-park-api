require "rails_helper"

RSpec.describe "Species", type: :request do
  it "lists species with id, name and diet" do
    species = create(:species, :carnivore, name: "Velociraptor")
    get "/species"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(a_hash_including("id" => species.id, "name" => "Velociraptor", "diet" => "carnivore"))
  end

  describe "POST /species" do
    it "creates a species" do
      post "/species", params: { name: "Dilophosaurus", diet: "carnivore" }
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("name" => "Dilophosaurus", "diet" => "carnivore")
    end

    it "returns 422 for an invalid diet" do
      post "/species", params: { name: "Dilophosaurus", diet: "omnivore" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("diet")
    end

    it "returns 422 for a duplicate name" do
      create(:species, name: "Rex")
      post "/species", params: { name: "Rex", diet: "carnivore" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("name")
    end
  end

  describe "PATCH /species/:id" do
    it "renames a species" do
      species = create(:species)
      patch "/species/#{species.id}", params: { name: "Renamed" }
      expect(response).to have_http_status(:ok)
      expect(species.reload.name).to eq("Renamed")
    end

    it "ignores a diet change" do
      species = create(:species, diet: "herbivore")
      patch "/species/#{species.id}", params: { diet: "carnivore" }
      expect(species.reload.diet).to eq("herbivore")
    end
  end

  describe "DELETE /species/:id" do
    it "deletes an unused species" do
      species = create(:species)
      delete "/species/#{species.id}"
      expect(response).to have_http_status(:no_content)
      expect(Species.exists?(species.id)).to be(false)
    end

    it "returns 422 and keeps a species that dinosaurs use" do
      dinosaur = create(:dinosaur)
      delete "/species/#{dinosaur.species_id}"
      expect(response).to have_http_status(:unprocessable_content)
      expect(Species.exists?(dinosaur.species_id)).to be(true)
    end
  end
end
