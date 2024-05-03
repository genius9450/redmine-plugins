class CreateChecklists < ActiveRecord::Migration[5.2]
  # require '../../app/models/checklist'

  def up

    if Redmine::Plugin.installed?(:redmine_kanban) && Gem::Version.new(Redmine::Plugin.find(:redmine_kanban).version) < Gem::Version.new("2.0.0")


      puts "ERROR: You use plugin redmine_kanban version " + Redmine::Plugin.find(:redmine_kanban).version
      puts "ERROR: For using advanced_checklists you need upgrade redmine_kanban to 2.0.0 or delete it"

      exit(1)
    end

    old_checklist_table_name = 'kanban_question_list'
    old_checklist_item_table_name = 'kanban_question_item'

    if ActiveRecord::Base.connection.table_exists? old_checklist_table_name
      rename_table old_checklist_table_name.to_s, AdvancedChecklist.table_name
    else
      create_table AdvancedChecklist.table_name do |t|
        t.string :title, :null => false, :limit => 100
        t.datetime :created_at, :null => false
        t.boolean :deleted, :default => false, :null => false
        t.datetime :updated_at, :null => false
        t.integer :sort_order, :default => 0, :null => false
        t.references :issue, :null => false
        t.references :created_by, :null => false
        t.string :list_type, :limit => 20, :default => ChecklistBase::TYPE_USUAL
      end
    end

    if ActiveRecord::Base.connection.table_exists? old_checklist_item_table_name
      rename_table old_checklist_item_table_name.to_s, AdvancedChecklistItem.table_name
    else
      create_table AdvancedChecklistItem.table_name do |t|
        t.boolean :done, :default => false, :null => false
        t.string :title, :null => false, :limit => 1000
        t.text :answer
        t.datetime :completed_at
        t.references :completed_by
        t.references :assigned_to
        t.datetime :due_date
        t.references :created_by, :null => false
        t.datetime :created_at, :null => false
        t.datetime :updated_at
        t.integer :sort_order, :default => 0, :null => false
        t.references :questionlist, :null => false
        t.boolean :deleted, :default => false, :null => false
        t.integer :answered_by_id, :null => true
        t.datetime :answered_at, :null => true
      end
    end





  end
end
