# frozen_string_literal: true

class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable,
       :confirmable, :jwt_authenticatable, jwt_revocation_strategy: self

  has_many :expenses, dependent: :destroy
  has_many :custom_categories, class_name: "Category", dependent: :destroy
  has_many :friendships_as_user, class_name: "Friendship", foreign_key: :user_id, dependent: :destroy
  has_many :friendships_as_friend, class_name: "Friendship", foreign_key: :friend_id, dependent: :destroy
  has_many :group_memberships, dependent: :destroy
  has_many :groups, through: :group_memberships
  has_many :created_groups, class_name: "Group", foreign_key: :created_by_id, dependent: :nullify
  has_many :expense_participants, dependent: :destroy
  has_many :repayments_owed, class_name: "Repayment", foreign_key: :from_user_id, dependent: :destroy
  has_many :repayments_owing, class_name: "Repayment", foreign_key: :to_user_id, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :notifications, dependent: :destroy

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :phone_number, presence: true, format: { with: /\A[+]?[\d\s\-().]{7,15}\z/, message: "is not valid" }
  validates :date_of_birth, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def initials
    "#{first_name&.first}#{last_name&.first}".upcase
  end

  def summary
    { id: id, first_name: first_name, last_name: last_name, full_name: full_name, initials: initials }
  end

  def friends
    friend_ids = Friendship.accepted.involving(self)
                           .pluck(:user_id, :friend_id)
                           .flatten.uniq - [ id ]
    User.where(id: friend_ids)
  end
end
