module Filterable
  extend ActiveSupport::Concern

  class InvalidFilter < StandardError; end

  private

  def filter_params(allowed)
    filters = params.fetch(:filter, {})
    raise InvalidFilter, "must be an object" unless filters.respond_to?(:keys)

    unknown = filters.keys - allowed.map(&:to_s)
    raise InvalidFilter, "unknown filter: #{unknown.join(', ')}" if unknown.any?
    raise InvalidFilter, "each filter takes a single value" if filters.values.any? { |value| value.respond_to?(:each) }

    filters.permit(*allowed)
  end
end
