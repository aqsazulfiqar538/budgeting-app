# frozen_string_literal: true

class CreateRepayments < ActiveRecord::Migration[8.0]
  def change
    create_table :repayments do |t|
      t.references :expense, null: false, foreign_key: true
      t.bigint :from_user_id, null: false
      t.bigint :to_user_id, null: false
      t.decimal :amount, null: false, precision: 12, scale: 2
      t.boolean :settled, null: false, default: false
      t.datetime :settled_at

      t.timestamps
    end

    add_foreign_key :repayments, :users, column: :from_user_id
    add_foreign_key :repayments, :users, column: :to_user_id
    add_index :repayments, [ :from_user_id, :settled ]
    add_index :repayments, [ :to_user_id, :settled ]
  end
end
