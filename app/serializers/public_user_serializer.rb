# frozen_string_literal: true

class PublicUserSerializer
  include JSONAPI::Serializer

  attributes :first_name, :last_name, :full_name, :initials
end
