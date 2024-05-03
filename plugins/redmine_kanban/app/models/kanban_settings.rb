# frozen_string_literal: true

class KanbanSettings
  PLUGIN_NAME = :redmine_kanban

  # rubocop:disable Style/IfWithBooleanLiteralBranches
  def self.is_tags_installed?
      false
  end
  # rubocop:enable Style/IfWithBooleanLiteralBranches

  def self.is_redmineup_tags_installed?
    defined?(RedmineupTags) == 'constant' && RedmineupTags.instance_of?(Module)
  end

  def self.is_additional_tags_installed?
    defined?(AdditionalTags) == 'constant' && AdditionalTags.instance_of?(Module)
  end

  def self.is_advanced_checklists_installed?
    defined?(AdvancedChecklists) == 'constant' && AdvancedChecklists.instance_of?(Module)
  end

  def self.is_custom_avatars_installed?
    defined?(RedminePeople) == 'constant' && RedminePeople.instance_of?(Module)
  end

  def self.is_redmineup_agile_installed?
    defined?(RedmineAgile) == 'constant' && RedmineAgile.instance_of?(Module)
  end

  def self.is_redmineup_additionals_installed?
    defined?(Additionals) == 'constant' && Additionals.instance_of?(Module)
  end

  def self.issues_limit
    1500
  end

  def self.default_query_filters
    {
      'status_id' => {operator: 'o', values: ['']},
      'assigned_to_id' => {operator: '=', values: ['me']}
    }
  end

  def self.is_use_kanban_issue_sizes?
    Setting["plugin_#{PLUGIN_NAME}".to_sym]['use_kanban_issue_sizes'].to_i.positive?
  end

  def self.set_use_kanban_issue_sizes(value)
    Setting["plugin_#{PLUGIN_NAME}".to_sym]['use_kanban_issue_sizes'] = (value ? '1' : '0')
  end

end
