class DinosaursController < ApplicationController
  def index
    render json: Dinosaur.includes(:species).order(:id)
  end

  def show
    render json: Dinosaur.find(params[:id])
  end

  def create
    render json: Dinosaur.create!(dinosaur_params), status: :created
  end

  def update
    dinosaur = Dinosaur.find(params[:id])
    dinosaur.update!(dinosaur_params)
    render json: dinosaur
  end

  private

  # cage_id is intentionally not permitted until the placement rules exist.
  def dinosaur_params
    params.permit(:name, :species_id)
  end
end
