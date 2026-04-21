class CreateRecommendations < ActiveRecord::Migration[8.0]
  def change
    create_table :recommendations do |t|
      t.references :user, null: false, foreign_key: true
      t.string :category, null: false
      t.text :prompt_input, null: false
      t.jsonb :ai_response, null: false, default: {}
      t.integer :action, null: false, default: 0

      t.timestamps
    end

    add_index :recommendations, :category
    add_index :recommendations, :action
  end
end
