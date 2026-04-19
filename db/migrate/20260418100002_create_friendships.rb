# frozen_string_literal: true

class CreateFriendships < ActiveRecord::Migration[8.0]
  def change
    create_table :friendships do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint :friend_id, null: false
      t.bigint :requested_by_id, null: false
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_foreign_key :friendships, :users, column: :friend_id
    add_foreign_key :friendships, :users, column: :requested_by_id
    add_index :friendships, [ :user_id, :friend_id ], unique: true
    add_index :friendships, :friend_id
    add_index :friendships, :status
    add_index :friendships, :requested_by_id
    add_check_constraint :friendships, "user_id < friend_id", name: "chk_friendship_canonical_order"
  end
end
