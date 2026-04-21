# frozen_string_literal: true

class Api::V1::GroupsController < ApplicationController
  before_action :authorize_member!, only: [ :show ]
  before_action :authorize_creator!, only: [ :update, :destroy ]

  def index
    groups = current_user.groups.where(deleted_at: nil) #groups that are not deleted
              .includes(:group_memberships, :users, :creator)

    render_paginated(groups, GroupSerializer)
  end

  def show
    group_expenses = group.expenses.where(deleted_at: nil) #expenses that are not deleted within the group
                           .includes(:category, expense_participants: :user, repayments: [ :from_user, :to_user ])
                           .recent

    render json: {
      **GroupSerializer.new(group).serializable_hash,
      expenses: ExpenseSerializer.new(group_expenses, include: [ :category ]).serializable_hash
    }
  end

  def create
    member_ids = validated_member_ids
    # return if performed?

    user_group = current_user.created_groups.new(group_params)

    if user_group.save
      user_group.group_memberships.create(user_id: current_user.id) #adding current user
      
      member_ids.each do |uid|
        user_group.group_memberships.create(user_id: uid) #adding valid friends 
      end

      user_group.reload
      render json: GroupSerializer.new(user_group).serializable_hash, status: :created
    else
      render_error(user_group.errors.full_messages)
    end
  end

  def update
    if group.update(group_params)
      render json: GroupSerializer.new(group.reload).serializable_hash
    else
      render_error(group.errors.full_messages)
    end
  end

  def destroy
    group.update!(deleted_at: Time.current)
    head :no_content
  end

  private

  def group
    @group ||= Group.find(params[:id])
  end

  def authorize_member!
    render_error("Not a member of this group", status: :forbidden) unless group.member?(current_user)
  end

  def authorize_creator!
    render_error("Only the group creator can perform this action", status: :forbidden) unless group.created_by_id == current_user.id
  end

  def group_params
    params.require(:group).permit(:name, :group_type)
  end

  def validated_member_ids
    ids = params[:member_ids]

    if !ids.is_a?(Array) || ids.reject { |id| id.to_i == current_user.id }.empty?
      render_error("A group must have at least one other member")
      return []
    end

    friend_ids = current_user.friends.pluck(:id)

    valid_ids = []

    ids.each do |id|
      id = id.to_i

      next if id == current_user.id
      next unless friend_ids.include?(id)

      valid_ids << id
    end

    if valid_ids.empty?
      render_error("At least one member must be a friend")
      return []
    end

    valid_ids
  end
end
