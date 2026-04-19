# frozen_string_literal: true

class CreateExpenseParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :expense_participants do |t|
      t.references :expense, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :paid_share, null: false, default: 0, precision: 12, scale: 2
      t.decimal :owed_share, null: false, default: 0, precision: 12, scale: 2

      t.timestamps
    end

    add_index :expense_participants, [ :expense_id, :user_id ], unique: true
  end
end
