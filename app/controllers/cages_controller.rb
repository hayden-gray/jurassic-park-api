class CagesController < ApplicationController
  include Filterable

  FILTERS = %i[id power_status].freeze

  def index
    render json: Cage.includes(:dinosaurs).where(filter_params(FILTERS)).order(:id)
  end

  def show
    render json: Cage.find(params[:id])
  end

  def create
    render json: Cage.create!(cage_params), status: :created
  end

  def update
    cage = Cage.find(params[:id])
    cage.with_lock { cage.update!(cage_params) }

    render json: cage
  end

  def destroy
    cage = Cage.find(params[:id])
    cage.with_lock { cage.destroy! }
    head :no_content
  end

  private

  def cage_params
    params.permit(:capacity, :power_status)
  end
end
