class CreateExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :expenses do |t|
      t.references :user, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.string :title, null: false
      t.decimal :amount, null: false, precision: 12, scale: 2
      t.date :start_date, null: false
      t.date :end_date
      t.text :notes

      t.timestamps
    end

    add_index :expenses, [ :user_id, :start_date ]
    add_index :expenses, [ :user_id, :category_id ]
  end
end
