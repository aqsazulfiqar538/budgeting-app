# frozen_string_literal: true

class Api::V1::SessionsController < Devise::SessionsController
  respond_to :json
  skip_before_action :authenticate_user!
  skip_before_action :verify_signed_out_user, only: [ :create ]

  private

  def respond_with(resource, _opts = {})
    render json: {
      message: "Logged in successfully.",
      user: {
        id: resource.id,
        email: resource.email,
        first_name: resource.first_name,
        last_name: resource.last_name
      }
    }, status: :ok
  end

  def respond_to_on_destroy(_resource_or_scope = nil)
    if request.headers["Authorization"].present?
      render json: { message: "Logged out successfully." }, status: :ok
    else
      render json: { message: "No active session." }, status: :unauthorized
    end
  end
end
