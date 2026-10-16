require "rails_helper"

RSpec.describe "Cages", type: :request do
  describe "POST /cages" do
    it "creates a cage" do
      post "/cages", params: { capacity: 3 }
      expect(response).to have_http_status(:created)
      expect(response.parsed_body).to include("capacity" => 3, "power_status" => "ACTIVE")
    end

    it "returns field-keyed errors for invalid input" do
      post "/cages", params: { capacity: 0 }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("capacity")
    end

    it "returns 422 for a missing capacity" do
      post "/cages", params: {}
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /cages" do
    it "lists cages" do
      create_list(:cage, 2)
      get "/cages"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.size).to eq(2)
    end

    it "filters by power status" do
      active = create(:cage)
      create(:cage, :down)
      get "/cages", params: { power_status: "ACTIVE" }
      expect(response.parsed_body.map { |c| c["id"] }).to eq([active.id])
    end

    it "returns an empty list for an unknown power status filter" do
      create(:cage)
      get "/cages", params: { power_status: "BROKEN" }
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq([])
    end

    it "accepts a lowercase power status filter" do
      create(:cage)
      down = create(:cage, :down)
      get "/cages", params: { power_status: "down" }
      expect(response.parsed_body.map { |c| c["id"] }).to eq([down.id])
    end

  end

  describe "GET /cages/:id" do
    it "returns the cage" do
      cage = create(:cage)
      get "/cages/#{cage.id}"
      expect(response.parsed_body["id"]).to eq(cage.id)
    end

    it "returns 404 with an errors body when missing" do
      get "/cages/0"
      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["errors"]).to have_key("base")
    end
  end

  describe "PATCH /cages/:id" do
    it "accepts lowercase power status input and returns the uppercase literal" do
      cage = create(:cage)
      patch "/cages/#{cage.id}", params: { power_status: "down" }
      expect(response.parsed_body["power_status"]).to eq("DOWN")
    end

    it "updates power status" do
      cage = create(:cage)
      patch "/cages/#{cage.id}", params: { power_status: "DOWN" }
      expect(response).to have_http_status(:ok)
      expect(cage.reload).to be_down
    end

    it "returns 422 when powering off a cage with dinosaurs" do
      cage = create(:cage)
      create(:dinosaur, cage: cage)
      patch "/cages/#{cage.id}", params: { power_status: "DOWN" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("power_status")
      expect(cage.reload).to be_active
    end

    it "returns 422 when lowering capacity below occupancy" do
      cage = create(:cage, capacity: 3)
      create_list(:dinosaur, 2, cage: cage)
      patch "/cages/#{cage.id}", params: { capacity: 1 }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("capacity")
    end

    it "returns 422 for an invalid power status" do
      cage = create(:cage)
      patch "/cages/#{cage.id}", params: { power_status: "BROKEN" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("power_status")
    end
  end

  describe "DELETE /cages/:id" do
    it "deletes an empty cage" do
      cage = create(:cage)
      delete "/cages/#{cage.id}"
      expect(response).to have_http_status(:no_content)
      expect(Cage.exists?(cage.id)).to be(false)
    end

    it "returns 422 and keeps a cage that has dinosaurs" do
      cage = create(:cage)
      create(:dinosaur, cage: cage)
      delete "/cages/#{cage.id}"
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("base")
      expect(Cage.exists?(cage.id)).to be(true)
    end

    it "returns 404 for a missing cage" do
      delete "/cages/0"
      expect(response).to have_http_status(:not_found)
    end
  end

  it "reports the dinosaur count" do
    cage = create(:cage)
    create_list(:dinosaur, 2, cage: cage)
    get "/cages/#{cage.id}"
    expect(response.parsed_body["dinosaur_count"]).to eq(2)
  end
end
