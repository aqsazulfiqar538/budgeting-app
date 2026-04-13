class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :recommendations, dependent: :destroy

  validates :first_name, presence: true, length: { maximum: 50 }
  validates :last_name, presence: true, length: { maximum: 50 }
  validates :phone_number, presence: true, format: { with: /\A[+]?[\d\s\-().]{7,15}\z/, message: "is not valid" }
  validates :date_of_birth, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end

  def inactive?
    recommendations.last_14_days.none?
  end
end
