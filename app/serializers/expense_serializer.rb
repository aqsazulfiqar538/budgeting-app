class ExpenseSerializer
  include JSONAPI::Serializer
 
  attributes :title, :amount, :category_id, :start_date, :end_date, :notes, :created_at, :updated_at
 
  belongs_to :category, serializer: CategorySerializer
end
