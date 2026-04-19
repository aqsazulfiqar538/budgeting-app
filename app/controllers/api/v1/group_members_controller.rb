# frozen_string_literal: true

class Api::V1::GroupMembersController < ApplicationController
  before_action :set_group
  before_action :authorize_member!

  # POST /api/v1/groups/:group_id/members
  def create
    user = User.find(params[:user_id])

    unless current_user.friends.exists?(id: user.id)
      render_error("Can only add friends to groups", status: :forbidden)
      return
    end

    membership = @group.group_memberships.new(user: user)
    if membership.save
      NotificationService.added_to_group(@group, user, current_user)
      @group.reload
      render json: GroupSerializer.new(@group).serializable_hash, status: :created
    else
      render_error(membership.errors.full_messages)
    end
  end

  # DELETE /api/v1/groups/:group_id/members/:id
  def destroy
    membership = @group.group_memberships.find_by!(user_id: params[:id])
    user = membership.user

    if user.id == @group.created_by_id
      render_error("Cannot remove the group creator", status: :forbidden)
      return
    end

    # Check for unsettled repayments in this group's expenses
    group_expense_ids = @group.expenses.active.pluck(:id)
    unsettled = Repayment.where("settled = :settled AND expense_id IN (:expense_ids) AND (from_user_id = :uid OR to_user_id = :uid)",
                                settled: false,
                                expense_ids: group_expense_ids,
                                uid: user.id
                                )

    if unsettled.exists?
      total = unsettled.sum(:amount)
      render_error("Cannot remove #{user.first_name} — they have Rs. #{total} in unsettled expenses in this group. Settle first.")
      return
    end

    NotificationService.removed_from_group(@group, user, current_user)
    membership.destroy
    head :no_content
  end

  private

  def set_group
    @group = Group.find(params[:group_id])
  end

  def authorize_member!
    render_error("Not a member of this group", status: :forbidden) unless @group.member?(current_user)
  end
end
