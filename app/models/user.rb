class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  validates :first_name, presence: true, length: {maximum: 20}
  validates :last_name, presence: true, length: {maximum: 20}
  validates :phone_number, presence: true, format: { with: /\A[+]?[\d\s\-().]{7,15}\z/, message: "is not valid" }
  validates :date_of_birth, presence: true

  def full_name
    "#{first_name} #{last_name}"
  end
end
