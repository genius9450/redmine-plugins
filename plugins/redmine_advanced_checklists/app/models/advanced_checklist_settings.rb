# frozen_string_literal: true

class AdvancedChecklistSettings
  MODULE_NAME = :advanced_checklists
  PLUGIN_NAME = :redmine_advanced_checklists

  def self.is_all_should_be_assigned?
    Setting["plugin_#{PLUGIN_NAME}".to_sym][:checklists_should_be_assigned].to_i.positive?
  end

  def self.is_respect_checklist_assigners_in_filter?
    Setting["plugin_#{PLUGIN_NAME}".to_sym][:respect_checklist_assigners_in_filter].to_i.positive?
  end

  def self.is_respect_checklist_assigners_in_filter(value)
    Setting["plugin_#{PLUGIN_NAME}".to_sym][:respect_checklist_assigners_in_filter] = value.to_i
  end

  def self.is_kanban_installed?
    defined?(KanbanQuery) == 'constant' && KanbanQuery.instance_of?(Class)
  end

end
