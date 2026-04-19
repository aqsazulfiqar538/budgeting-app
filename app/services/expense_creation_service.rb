# frozen_string_literal: true

class ExpenseCreationService
  attr_reader :expense, :errors

  def initialize(user:, expense_params:, split_equally: false, participants: nil, group_id: nil)
    @user = user
    @expense_params = expense_params
    @split_equally = split_equally
    @participants_data = participants
    @group_id = group_id
    @errors = []
  end

  def call
    success = true

    ActiveRecord::Base.transaction do
      validate_group_membership! if @group_id.present?
      validate_participants_are_friends! if shared?
      create_expense!
      create_participants! if shared?
      validate_split_totals! if shared? && @participants_data.present? && !@split_equally
      create_repayments! if shared?
      create_system_comment!
    rescue SplitValidationError => e
      @errors = [ e.message ]
      success = false
      raise ActiveRecord::Rollback
    rescue ActiveRecord::RecordInvalid => e
      @errors = e.record.errors.full_messages
      success = false
      raise ActiveRecord::Rollback
    end

    return nil unless success

    NotificationService.expense_created(@expense, @user) if shared? && @expense
    expense
  end

  class SplitValidationError < StandardError; end

  private

  def validate_group_membership!
    group = Group.find(@group_id)
    raise SplitValidationError, "You are not a member of this group" unless group.member?(@user)
  end

  def validate_participants_are_friends!
    participant_ids = resolve_participant_user_ids
    other_ids = participant_ids - [ @user.id ]
    return if other_ids.empty?

    friend_ids = @user.friends.pluck(:id)
    unauthorized = other_ids - friend_ids

    if unauthorized.any?
      raise SplitValidationError, "Users #{unauthorized.join(', ')} are not your friends"
    end
  end

  def create_expense!
    @expense = @user.expenses.new(@expense_params)
    @expense.group_id = @group_id if @group_id.present?
    @expense.save!
  end

  def shared?
    @split_equally || @participants_data.present?
  end

  def create_participants!
    if @split_equally
      create_equal_split!
    elsif @participants_data.present?
      create_custom_split!
    end
  end

  def create_equal_split!
    user_ids = resolve_participant_user_ids
    return if user_ids.size < 2

    base_share = (@expense.amount / user_ids.size).floor(2)
    remainder = @expense.amount - (base_share * user_ids.size)

    user_ids.each_with_index do |uid, i|
      share = i == 0 ? base_share + remainder : base_share
      paid = uid == @user.id ? @expense.amount : 0

      @expense.expense_participants.create!(
        user_id: uid,
        paid_share: paid,
        owed_share: share
      )
    end
  end

  def create_custom_split!
    @participants_data.each do |p|
      @expense.expense_participants.create!(
        user_id: p[:user_id],
        paid_share: p[:paid_share].to_d,
        owed_share: p[:owed_share].to_d
      )
    end
  end

  def validate_split_totals!
    total_owed = @expense.expense_participants.sum(:owed_share)
    total_paid = @expense.expense_participants.sum(:paid_share)

    if total_owed != @expense.amount
      raise SplitValidationError, "Total owed shares (#{total_owed}) must equal expense amount (#{@expense.amount})"
    end

    if total_paid != @expense.amount
      raise SplitValidationError, "Total paid shares (#{total_paid}) must equal expense amount (#{@expense.amount})"
    end
  end

  def create_repayments!
    payers = @expense.expense_participants.select { |p| p.paid_share > p.owed_share }
    owers = @expense.expense_participants.select { |p| p.owed_share > p.paid_share }

    total_payer_surplus = payers.sum { |p| p.paid_share - p.owed_share }

    owers.each do |ower|
      debt = ower.owed_share - ower.paid_share

      payers.each do |payer|
        payer_surplus = payer.paid_share - payer.owed_share
        payer_share = (debt * payer_surplus / total_payer_surplus).round(2)
        next if payer_share <= 0

        @expense.repayments.create!(
          from_user_id: ower.user_id,
          to_user_id: payer.user_id,
          amount: payer_share
        )
      end
    end
  end

  def resolve_participant_user_ids
    if @group_id.present? && @participants_data.blank?
      Group.find(@group_id).members.pluck(:id)
    elsif @participants_data.present?
      @participants_data.map { |p| p[:user_id].to_i }
    else
      [ @user.id ]
    end
  end

  def create_system_comment!
    message = if shared?
      "#{@user.full_name} created a shared expense '#{@expense.title}' — Rs. #{@expense.amount}"
    else
      "#{@user.full_name} added '#{@expense.title}' — Rs. #{@expense.amount}"
    end

    @expense.comments.create!(
      user: @user,
      content: message,
      comment_type: :system_comment
    )
  end
end
