# frozen_string_literal: true

class CreateKanbanIssueSizes < ActiveRecord::Migration[5.2]
  def self.up
    create_table(KanbanIssueSize.table_name) do |t|
      t.column(:name, :string, null: false, length: 20)
      t.column(:sort_order, :integer, default: 0, null: false)
      t.column(:created_at, :datetime)
      t.column(:updated_at, :datetime)
    end
    add_reference(KanbanIssue.table_name, :size, foreign_key: {to_table: KanbanIssueSize.table_name})
  end

  def self.down
    remove_reference(KanbanIssue.table_name, :size)
    drop_table(KanbanIssueSize.table_name)
  end
end
