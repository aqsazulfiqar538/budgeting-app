# frozen_string_literal: true

class Api::V1::PasswordsController < Devise::PasswordsController
  respond_to :json
  skip_before_action :authenticate_user!

  # POST /api/v1/password — send reset email
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)

    if successfully_sent?(resource)
      render json: { message: "Reset password instructions sent to your email." }, status: :ok
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # PUT/PATCH /api/v1/password — reset password with token
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)

    if resource.errors.empty?
      render json: { message: "Password has been reset successfully." }, status: :ok
    else
      render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity
    end
  end
end
