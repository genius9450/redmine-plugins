class AddItemDueDate < ActiveRecord::Migration[5.2]
  def change
    unless column_exists? AdvancedChecklistItem.table_name, :due_date
      add_column AdvancedChecklistItem.table_name, :due_date, :datetime
    end
  end
end
