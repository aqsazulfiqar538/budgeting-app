# frozen_string_literal: true

class Api::V1::CategoriesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index ]

  def index
    categories = if current_user
      Category.where(user_id: [ nil, current_user.id ])
              .where(active: true, parent_id: nil)
              .includes(:subcategories)
    else
      Category.system_categories.where(active: true, parent_id: nil).includes(:subcategories)
    end

    render json: CategorySerializer.new(categories, include: [ :subcategories ]).serializable_hash
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
