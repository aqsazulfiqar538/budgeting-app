# frozen_string_literal: true

class Api::V1::ConfirmationsController < Devise::ConfirmationsController
  respond_to :json
  skip_before_action :authenticate_user!

  # GET /api/v1/confirmation?confirmation_token=xxx
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      render json: { message: "Account confirmed successfully. You can now log in." }, status: :ok
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  # POST /api/v1/confirmation — resend confirmation email
  def respond_with(resource, _opts = {})
    if resource.errors.empty?
      render json: { message: "Confirmation email sent." }, status: :ok
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
