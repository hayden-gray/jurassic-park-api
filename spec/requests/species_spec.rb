require "rails_helper"

RSpec.describe "Species", type: :request do
  it "lists species with id, name and diet" do
    species = create(:species, :carnivore, name: "Velociraptor")
    get "/species"
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body).to include(a_hash_including("id" => species.id, "name" => "Velociraptor", "diet" => "carnivore"))
  end
end
