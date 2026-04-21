# frozen_string_literal: true

class CreateComments < ActiveRecord::Migration[8.0]
  def change
    create_table :comments do |t|
      t.references :expense, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :comment_type, null: false, default: 0
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :comments, [ :expense_id, :created_at ]
  end
end
