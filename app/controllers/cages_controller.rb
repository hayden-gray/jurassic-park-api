class CagesController < ApplicationController
  def index
    cages = Cage.includes(:dinosaurs).order(:id)
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
