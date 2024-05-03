# frozen_string_literal: true

module RedmineKanban
  module Patches
    module SettingsControllerPatch
      def self.included(base)
        base.class_eval do
          helper(:kanban_translate)
        end
      end
    end
  end
end

# rubocop:disable Style/IfUnlessModifier
unless SettingsController.included_modules.include?(RedmineKanban::Patches::SettingsControllerPatch)
  SettingsController.send(:include, RedmineKanban::Patches::SettingsControllerPatch)
end
# rubocop:enable Style/IfUnlessModifier
