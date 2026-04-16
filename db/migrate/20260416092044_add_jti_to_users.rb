class AddJtiToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :jti, :string, null: false, default: -> { 'gen_random_uuid()' }
    add_index :users, :jti, unique: true
  end
end
