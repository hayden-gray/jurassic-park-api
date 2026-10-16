require "rails_helper"

RSpec.describe "Dinosaurs", type: :request do
  let(:species) { create(:species, :carnivore, name: "Velociraptor") }

  describe "POST /dinosaurs" do
    it "creates a dinosaur with species name and diet in the response" do
      post "/dinosaurs", params: { name: "Blue", species_id: species.id }
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include(
        "name" => "Blue", "species_id" => species.id, "species" => "Velociraptor", "diet" => "carnivore", "cage_id" => nil
      )
    end

    it "returns 422 without a name" do
      post "/dinosaurs", params: { species_id: species.id }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("name")
    end

    it "returns 422 without a species" do
      post "/dinosaurs", params: { name: "Blue" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("species")
    end

    it "returns 422 for an unknown species_id" do
      post "/dinosaurs", params: { name: "Blue", species_id: 0 }
      expect(response).to have_http_status(:unprocessable_content)
    end

    it "places the dinosaur in a cage" do
      cage = create(:cage)
      post "/dinosaurs", params: { name: "Blue", species_id: species.id, cage_id: cage.id }
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["cage_id"]).to eq(cage.id)
    end

    it "returns 422 for a cage that does not exist" do
      post "/dinosaurs", params: { name: "Blue", species_id: species.id, cage_id: 0 }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("cage")
    end

    it "returns 422 for a cage that is powered down" do
      cage = create(:cage, :down)
      post "/dinosaurs", params: { name: "Blue", species_id: species.id, cage_id: cage.id }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]["cage"]).to include("is powered down")
    end
  end

  describe "GET /dinosaurs" do
    it "lists dinosaurs" do
      create_list(:dinosaur, 2)
      get "/dinosaurs"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
    end
  end

  describe "GET /dinosaurs/:id" do
    it "returns the dinosaur" do
      dinosaur = create(:dinosaur)
      get "/dinosaurs/#{dinosaur.id}"
      expect(response.parsed_body["id"]).to eq(dinosaur.id)
    end

    it "returns 404 when missing" do
      get "/dinosaurs/0"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "PATCH /dinosaurs/:id" do
    it "updates the name" do
      dinosaur = create(:dinosaur, name: "Blue")
      patch "/dinosaurs/#{dinosaur.id}", params: { name: "Echo" }
      expect(response).to have_http_status(:ok)
      expect(dinosaur.reload.name).to eq("Echo")
    end

    it "moves a dinosaur into a cage and back out" do
      dinosaur = create(:dinosaur)
      cage = create(:cage)
      patch "/dinosaurs/#{dinosaur.id}", params: { cage_id: cage.id }
      expect(dinosaur.reload.cage).to eq(cage)
      patch "/dinosaurs/#{dinosaur.id}", params: { cage_id: "" }
      expect(dinosaur.reload.cage).to be_nil
    end

    it "returns 422 when moving into a full cage" do
      cage = create(:cage, capacity: 1)
      create(:dinosaur, cage: cage)
      dinosaur = create(:dinosaur)
      patch "/dinosaurs/#{dinosaur.id}", params: { cage_id: cage.id }
      expect(response).to have_http_status(:unprocessable_content)
      expect(dinosaur.reload.cage).to be_nil
    end

    it "ignores species_id on update" do
      dinosaur = create(:dinosaur)
      original = dinosaur.species
      patch "/dinosaurs/#{dinosaur.id}", params: { species_id: create(:species).id }
      expect(dinosaur.reload.species).to eq(original)
    end

    it "returns 422 for a blank name" do
      dinosaur = create(:dinosaur)
      patch "/dinosaurs/#{dinosaur.id}", params: { name: "" }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
