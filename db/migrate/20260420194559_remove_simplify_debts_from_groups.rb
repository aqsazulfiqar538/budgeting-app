class RemoveSimplifyDebtsFromGroups < ActiveRecord::Migration[8.0]
  def change
    remove_column :groups, :simplify_debts, :boolean
  end
end
