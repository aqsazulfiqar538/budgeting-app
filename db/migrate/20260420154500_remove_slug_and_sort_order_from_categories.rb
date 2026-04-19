class RemoveSlugAndSortOrderFromCategories < ActiveRecord::Migration[7.0]
  def change
    remove_column :categories, :slug, :string
    remove_column :categories, :sort_order, :integer
  end
end
