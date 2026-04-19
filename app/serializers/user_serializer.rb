# frozen_string_literal: true

class UserSerializer
  include JSONAPI::Serializer

  attributes :first_name, :last_name, :email, :phone_number, :date_of_birth, :full_name, :initials
end
