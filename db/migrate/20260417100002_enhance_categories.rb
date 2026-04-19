class EnhanceCategories < ActiveRecord::Migration[8.0]
  def change
    add_reference :categories, :user, null: true, foreign_key: true
    add_reference :categories, :parent, null: true, foreign_key: { to_table: :categories }
    add_column :categories, :icon, :string

    remove_index :categories, :slug

    # System top-level categories: slug unique where no user and no parent
    add_index :categories, :slug, unique: true,
              where: "user_id IS NULL AND parent_id IS NULL",
              name: "idx_categories_slug_system_top"

    # System subcategories: slug unique per parent
    add_index :categories, [ :slug, :parent_id ], unique: true,
              where: "user_id IS NULL AND parent_id IS NOT NULL",
              name: "idx_categories_slug_system_sub"

    # User custom categories: slug unique per user
    add_index :categories, [ :slug, :user_id ], unique: true,
              where: "user_id IS NOT NULL",
              name: "idx_categories_slug_user"
  end
end
