# frozen_string_literal: true

class Api::V1::UsersController < ApplicationController
  def profile
    render json: UserSerializer.new(current_user).serializable_hash
  end

  def update_profile
    if current_user.update(user_params)
      render json: UserSerializer.new(current_user).serializable_hash
    else
      render_error(current_user.errors.full_messages)
    end
  end

  def search
    exclude_ids = [ current_user.id ] + current_user.friends.pluck(:id)
    users = User.where.not(id: exclude_ids)
    users = users.where("first_name ILIKE :q OR last_name ILIKE :q OR email ILIKE :q", q: "%#{params[:q]}%") if params[:q].present?
    users = users.limit(20)

    render json: PublicUserSerializer.new(users).serializable_hash
  end

  def show
    user = User.find(params[:id])
    render json: PublicUserSerializer.new(user).serializable_hash
  end

  private

  def user_params
    params.require(:user).permit(:first_name, :last_name, :phone_number, :date_of_birth)
  end
end
