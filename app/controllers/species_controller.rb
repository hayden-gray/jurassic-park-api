class SpeciesController < ApplicationController
  def index
    render json: Species.order(:id)
  end

  def create
    render json: Species.create!(params.permit(:name, :diet)), status: :created
  end

  def update
    species = Species.find(params[:id])
    species.update!(params.permit(:name))
    render json: species
  end

  def destroy
    Species.find(params[:id]).destroy!
    head :no_content
  end
end
