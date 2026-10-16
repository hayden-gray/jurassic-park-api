class CagesController < ApplicationController
  def index
    cages = Cage.order(:id)
    cages = cages.where(power_status: params[:power_status]) if params[:power_status].present?

    render json: cages
  end

  def show
    render json: Cage.find(params[:id])
  end

  def create
    render json: Cage.create!(cage_params), status: :created
  end

  def update
    cage = Cage.find(params[:id])
    cage.update!(cage_params)

    render json: cage
  end

  private

  def cage_params
    params.permit(:capacity, :power_status)
  end
end
