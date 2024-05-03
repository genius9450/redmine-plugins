# frozen_string_literal: true

module AdvancedChecklists
  module Patches
    module SettingPatch
      def self.included(base)
        base.extend(ClassMethods)
        base.class_eval do
          class << self
            alias_method :'redmine_advanced_checklists=_without', :plugin_redmine_advanced_checklists=
            alias_method :plugin_redmine_advanced_checklists=, :'redmine_advanced_checklists=_with'
          end
        end
      end

      module ClassMethods
        define_method(:'redmine_advanced_checklists=_with') do |settings|
          ids = settings[:project_ids].nil? ? [] : settings[:project_ids].map(&:to_i)
          Project.find_each do |project|
            if ids.include?(project.id)
              project.enable_module!('advanced_checklists')
            else
              project.disable_module!('advanced_checklists')
            end
            send(:'redmine_advanced_checklists=_without', settings)
          end
        end
      end
    end
  end
end

# rubocop:disable Style/IfUnlessModifier
unless Setting.included_modules.include?(AdvancedChecklists::Patches::SettingPatch)
  Setting.send(:include, AdvancedChecklists::Patches::SettingPatch)
end
# rubocop:enable Style/IfUnlessModifier
