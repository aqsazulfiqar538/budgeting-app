# == Schema Information
#
# Table name: group_memberships
#
#  id         :integer          not null, primary key
#  group_id   :integer          not null
#  user_id    :integer          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_group_memberships_on_group_id              (group_id)
#  index_group_memberships_on_group_id_and_user_id  (group_id,user_id) UNIQUE
#  index_group_memberships_on_user_id               (user_id)
#

# frozen_string_literal: true

class GroupMembership < ApplicationRecord
  belongs_to :group
  belongs_to :user

  attr_accessor :adder

  validates :user_id, uniqueness: { scope: :group_id, message: "is already a member" }
  validate :user_must_be_friend_of_adder, on: :create

  def removable?
    return false if user.id == group.created_by_id

    group_expense_ids = group.expenses.active.pluck(:id)
    Repayment.where(settled: false, expense_id: group_expense_ids)
    .where("from_user_id = :uid OR to_user_id = :uid", uid: user.id).none?
  end

  def user_must_be_friend_of_adder
    return unless adder
    errors.add(:user, "must be a friend") unless adder.friends.exists?(id: user.id)
  end
end
