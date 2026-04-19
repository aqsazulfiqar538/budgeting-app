# frozen_string_literal: true

class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.bigint :created_by_id, null: false
      t.integer :notification_type, null: false
      t.text :content, null: false
      t.string :source_type
      t.bigint :source_id
      t.datetime :read_at

      t.timestamps
    end

    add_foreign_key :notifications, :users, column: :created_by_id
    add_index :notifications, [ :user_id, :read_at, :created_at ], name: "idx_notifications_user_read_created"
    add_index :notifications, [ :source_type, :source_id ]
  end
end
