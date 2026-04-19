# frozen_string_literal: true

class Api::V1::GroupsController < ApplicationController
  before_action :set_group, only: [ :show, :update, :destroy, :restore ]
  before_action :authorize_member!, only: [ :show ]
  before_action :authorize_creator!, only: [ :update, :destroy, :restore ]

  # GET /api/v1/groups
  def index
    groups = current_user.groups.active
              .includes(:group_memberships, :members, :creator)
    pagy, records = pagy(groups)
    render json: {
      **GroupSerializer.new(records).serializable_hash,
      meta: pagy_metadata(pagy)
    }
  end

  # GET /api/v1/groups/:id
  def show
    group_expenses = @group.expenses.active
                           .includes(:category, expense_participants: :user, repayments: [ :from_user, :to_user ])
                           .recent

    render json: {
      **GroupSerializer.new(@group).serializable_hash,
      expenses: ExpenseSerializer.new(group_expenses, include: [ :category ]).serializable_hash
    }
  end

  # POST /api/v1/groups
  def create
    member_ids = validated_member_ids
    return if performed?

    group = current_user.created_groups.new(group_params)

    ActiveRecord::Base.transaction do
      if group.save
        group.group_memberships.create!(user_id: current_user.id)
        add_members(group, member_ids)

        group.reload
        render json: GroupSerializer.new(group).serializable_hash, status: :created
      else
        render_error(group.errors.full_messages)
      end
    end
  end

  # PATCH /api/v1/groups/:id
  def update
    if @group.update(group_params)
      render json: GroupSerializer.new(@group.reload).serializable_hash
    else
      render_error(@group.errors.full_messages)
    end
  end

  # DELETE /api/v1/groups/:id
  def destroy
    @group.soft_delete!
    head :no_content
  end

  # POST /api/v1/groups/:id/restore
  def restore
    @group.restore!
    render json: GroupSerializer.new(@group).serializable_hash
  end

  private

  def set_group
    @group = Group.find(params[:id])
  end

  def authorize_member!
    render_error("Not a member of this group", status: :forbidden) unless @group.member?(current_user)
  end

  def authorize_creator!
    render_error("Only the group creator can perform this action", status: :forbidden) unless @group.created_by_id == current_user.id
  end

  def group_params
    params.require(:group).permit(:name, :group_type, :simplify_debts)
  end

  def validated_member_ids
    ids = params[:member_ids]

    unless ids.is_a?(Array) && ids.reject { |id| id.to_i == current_user.id }.any?
      render_error("A group must have at least one other member")
      return []
    end

    friend_ids = current_user.friends.pluck(:id)
    valid_ids = ids.map(&:to_i).select { |id| id != current_user.id && friend_ids.include?(id) }

    if valid_ids.empty?
      render_error("At least one member must be a friend")
      return []
    end

    valid_ids
  end

  def add_members(group, member_ids)
    member_ids.each do |uid|
      group.group_memberships.find_or_create_by(user_id: uid)
    end
  end
end
