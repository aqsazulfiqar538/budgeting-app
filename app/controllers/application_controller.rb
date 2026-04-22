# frozen_string_literal: true

class ApplicationController < ActionController::API
  include Pagy::Backend

  before_action :authenticate_user!
  before_action :configure_permitted_parameters, if: :devise_controller?

  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [
      :first_name, :last_name, :phone_number, :date_of_birth
    ])
  end

  private

  def render_success(data = nil, status: :ok, message: nil)
    body = {}
    body[:message] = message if message
    body[:data] = data if data
    render json: body, status: status
  end

  def render_error(errors, status: :unprocessable_entity)
    error_list = errors.is_a?(Array) ? errors : [ errors ]
    render json: { errors: error_list }, status: status
  end

  def render_paginated(collection, serializer, includes: nil, serializer_options: {})
    pagy, records = pagy(collection)

    options = serializer_options.dup
    options[:include] = includes if includes

    render json: {
      **serializer.new(records, **options).serializable_hash,
      meta: pagy_metadata(pagy)
    }
  end

  def pagy_metadata(pagy)
    {
      current_page: pagy.page,
      total_pages: pagy.pages,
      total_count: pagy.count,
      per_page: pagy.limit,
      next_page: pagy.next,
      prev_page: pagy.prev
    }
  end

  def not_found
    render_error("Record not found", status: :not_found)
  end
end
