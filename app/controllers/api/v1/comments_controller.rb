# frozen_string_literal: true

class Api::V1::CommentsController < ApplicationController
  before_action :set_expense
  before_action :authorize_participant!, only: [ :create ]

  def index
    comments = @expense.comments.includes(:user)
    render_paginated(comments, CommentSerializer)
  end

  def create
    comment = @expense.comments.new(comment_params.merge(user: current_user, comment_type: :user_comment))

    if comment.save
      NotificationService.comment_added(comment)
      render json: CommentSerializer.new(comment).serializable_hash, status: :created
    else
      render_error(comment.errors.full_messages)
    end
  end

  def destroy
    comment = @expense.comments.find(params[:id])

    if comment.user_id != current_user.id
      render_error("Can only delete your own comments", status: :forbidden)
      return
    end

    comment.destroy
    head :no_content
    rescue ActiveRecord::RecordNotDestroyed => e
      render_error(e.full_messages)
    end
  end

  private

  def comment_params
    params.permit(:content)
  end

  def set_expense
    @expense = Expense.visible_to(current_user).find(params[:expense_id])
  end

  def authorize_participant!
    return if @expense.user_id == current_user.id
    return if @expense.expense_participants.exists?(user_id: current_user.id)

    render_error("Only participants can comment on this expense", status: :forbidden)
  end
end
