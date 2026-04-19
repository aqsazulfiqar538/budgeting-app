# frozen_string_literal: true

class CategorySerializer
  include JSONAPI::Serializer

  attributes :name, :active, :parent_id

  attribute :custom, &:user_id?

  has_many :subcategories, serializer: CategorySerializer
end
