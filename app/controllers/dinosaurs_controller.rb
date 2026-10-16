class DinosaursController < ApplicationController
  include Filterable

  FILTERS = %i[id species_id cage_id].freeze

  def index
    render json: Dinosaur.includes(:species).where(filter_params(FILTERS)).order(:id)
  end

  def show
    render json: Dinosaur.find(params[:id])
  end

  def create
    dinosaur = Dinosaur.new(params.permit(:name, :species_id))
    save_with_cage(dinosaur)

    render json: dinosaur, status: :created
  end

  def update
    dinosaur = Dinosaur.find(params[:id])
    dinosaur.assign_attributes(params.permit(:name))
    save_with_cage(dinosaur)

    render json: dinosaur
  end

  private

  def save_with_cage(dinosaur)
    if params[:cage_id].present?
      CageAssignment.call(dinosaur: dinosaur, cage_id: params[:cage_id])
    else
      dinosaur.cage = nil if params.key?(:cage_id)
      dinosaur.save!
    end
  end
end
