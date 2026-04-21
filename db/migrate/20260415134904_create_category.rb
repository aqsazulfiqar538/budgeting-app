class CreateCategory < ActiveRecord::Migration[8.0]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.boolean :active, null: false, default: true
      t.integer :sort_order, null: false, default: 0

      t.timestamps
    end

    add_index :categories, :slug, unique: true
  end
end
