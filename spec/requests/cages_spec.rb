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

    it "returns 422 for an invalid power status" do
      cage = create(:cage)
      patch "/cages/#{cage.id}", params: { power_status: "BROKEN" }
      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("power_status")
    end
  end
end
