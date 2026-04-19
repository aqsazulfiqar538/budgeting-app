# frozen_string_literal: true

class CreateGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :groups do |t|
      t.string :name, null: false
      t.integer :group_type, null: false, default: 0
      t.bigint :created_by_id, null: false
      t.boolean :simplify_debts, null: false, default: false
      t.datetime :deleted_at

      t.timestamps
    end

    add_foreign_key :groups, :users, column: :created_by_id
    add_index :groups, :created_by_id
    add_index :groups, :deleted_at
  end
end
