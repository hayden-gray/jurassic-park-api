class ApplicationController < ActionController::API
  rescue_from ActiveRecord::RecordInvalid do |e|
    render json: { errors: e.record.errors.to_hash }, status: :unprocessable_content
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render json: { errors: { base: ["#{e.model || 'Record'} not found"] } }, status: :not_found
  end
end
