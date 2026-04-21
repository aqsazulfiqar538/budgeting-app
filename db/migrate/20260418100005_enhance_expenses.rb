# frozen_string_literal: true

class EnhanceExpenses < ActiveRecord::Migration[8.0]
  def change
    add_reference :expenses, :group, null: true, foreign_key: true
    add_column :expenses, :deleted_at, :datetime

    add_index :expenses, :deleted_at
  end
end
