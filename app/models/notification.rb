# == Schema Information
#
# Table name: notifications
#
#  id                :integer          not null, primary key
#  user_id           :integer          not null
#  created_by_id     :integer          not null
#  notification_type :integer          not null
#  content           :text             not null
#  source_type       :string
#  source_id         :integer
#  read_at           :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  idx_notifications_user_read_created               (user_id,read_at,created_at)
#  index_notifications_on_source_type_and_source_id  (source_type,source_id)
#  index_notifications_on_user_id                    (user_id)
#

# frozen_string_literal: true

class Notification < ApplicationRecord
  belongs_to :user
  belongs_to :created_by, class_name: "User" 
  belongs_to :source, polymorphic: true, optional: true

  enum :notification_type, {
    expense_added: 0,
    expense_updated: 1,
    expense_deleted: 2,
    comment_added: 3,
    added_to_group: 4,
    removed_from_group: 5,
    group_deleted: 6,
    friend_added: 7,
    friend_removed: 8,
    debt_settled: 9
  }

  validates :content, presence: true

  scope :unread, -> { where(read_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
end
