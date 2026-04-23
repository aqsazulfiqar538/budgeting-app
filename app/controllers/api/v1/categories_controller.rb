# frozen_string_literal: true

class Api::V1::CategoriesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index ]

  def index
    categories = Category.system_categories.active_root_categories.includes(:subcategories)
    categories = categories.where(user_id: [ nil, current_user.id ]) if current_user

    render json: CategorySerializer.new(categories, include: [ :subcategories ]).serializable_hash # what does include do?
  end

  def create
    category = current_user.custom_categories.new(category_params)

    if category.save
      render json: CategorySerializer.new(category).serializable_hash, status: :created
    else
      render_error(category.errors.full_messages)
    end
  end

  private

  def category_params
    params.require(:category).permit(:name, :parent_id)
  end
end
