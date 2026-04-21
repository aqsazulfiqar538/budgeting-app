# frozen_string_literal: true

class DropUnusedAiTables < ActiveRecord::Migration[8.0]
  def up
    # Remove FK constraints first, then drop tables in dependency order
    remove_foreign_key :messages, :tool_calls, if_exists: true
    remove_foreign_key :messages, :chats, if_exists: true
    remove_foreign_key :messages, column: :model_id, if_exists: true
    remove_foreign_key :tool_calls, :messages, if_exists: true
    remove_foreign_key :chats, column: :model_id, if_exists: true

    drop_table :tool_calls, if_exists: true
    drop_table :messages, if_exists: true
    drop_table :chats, if_exists: true
    drop_table :models, if_exists: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "AI tables were removed. Re-run RubyLLM setup if needed."
  end
end
