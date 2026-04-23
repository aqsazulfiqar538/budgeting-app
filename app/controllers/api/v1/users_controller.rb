# frozen_string_literal: true

class Api::V1::UsersController < ApplicationController
  # GET /api/v1/users/me
  def me
    render json: UserSerializer.new(current_user).serializable_hash
  end

  # PATCH /api/v1/users/me
  def update_me
    if current_user.update(user_params)
      render json: UserSerializer.new(current_user).serializable_hash
    else
      render_error(current_user.errors.full_messages)
    end
  end

  # GET /api/v1/users/search?q=name
  def search
    exclude_ids = [ current_user.id ] + current_user.friends.pluck(:id)
    users = User.where.not(id: exclude_ids)
    users = users.where("first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?
    users = users.limit(20)

    render json: PublicUserSerializer.new(users).serializable_hash
  end

  # GET /api/v1/users/:id
  def show
    user = User.find_by(id: params[:id])
    render json: PublicUserSerializer.new(user).serializable_hash
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone_number, :date_of_birth)
  end
end
