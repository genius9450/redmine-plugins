# frozen_string_literal: true

require_dependency 'queries_helper'

module AdvancedChecklists
  module Patches
    module ProjectsHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method(:project_settings_tabs_without_advanced_checklists, :project_settings_tabs)
          alias_method(:project_settings_tabs, :project_settings_tabs_with_advanced_checklists)
        end
      end

      module InstanceMethods
        def project_settings_tabs_with_advanced_checklists
          tabs = project_settings_tabs_without_advanced_checklists
          if AdvancedChecklistSettings.is_allow_manage_templates?(User.current, @project)
            tabs.push(:name => 'advanced_checklists',
                      :partial => 'settings/project/advanced_checklists_settings',
                      :label => :label_checklist_plural)
          end
          tabs
        end
      end
    end
  end
end

# rubocop:disable Style/IfUnlessModifier
unless ProjectsHelper.included_modules.include?(AdvancedChecklists::Patches::ProjectsHelperPatch)
  ProjectsHelper.send(:include, AdvancedChecklists::Patches::ProjectsHelperPatch)
end
# rubocop:enable Style/IfUnlessModifier
