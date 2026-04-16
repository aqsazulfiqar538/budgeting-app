class User < ApplicationRecord
  include Devise::JWT::RevocationStrategies::JTIMatcher
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
       :recoverable, :rememberable, :validatable, :confirmable,
       :jwt_authenticatable, jwt_revocation_strategy: self

  has_many :expenses, dependent: :destroy

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :phone_number, presence: true, format: { with: /\A[+]?[\d\s\-().]{7,15}\z/, message: "is not valid" }
  validates :date_of_birth, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
