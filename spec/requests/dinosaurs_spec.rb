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

    it "ignores cage_id until placement rules exist" do
      cage = create(:cage)
      post "/dinosaurs", params: { name: "Blue", species_id: species.id, cage_id: cage.id }
      expect(response.parsed_body["cage_id"]).to be_nil
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

    it "returns 422 for a blank name" do
      dinosaur = create(:dinosaur)
      patch "/dinosaurs/#{dinosaur.id}", params: { name: "" }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
