class SpeciesController < ApplicationController
  def index
    render json: Species.order(:id)
  end
end
