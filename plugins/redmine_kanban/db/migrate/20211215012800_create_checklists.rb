class CreateChecklists < ActiveRecord::Migration[5.2]

  def change
    create_table KanbanIssue.table_name do |t|
      t.string :block_reason, :null => true, :limit => 1000
      t.integer :sort_order, :default => 1, :null => false
      t.references :issue, :null => false
      t.datetime :blocked_at, :null => true
    end
  end
end
