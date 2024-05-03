# frozen_string_literal: true

module RedmineKanban
  module Patches
    module IssuesControllerPatch
      def self.included(base)
        base.class_eval do
          helper(:kanban_translate)
        end
      end
    end
  end
end

# rubocop:disable Style/IfUnlessModifier
unless IssuesController.included_modules.include?(RedmineKanban::Patches::IssuesControllerPatch)
  IssuesController.send(:include, RedmineKanban::Patches::IssuesControllerPatch)
end
# rubocop:enable Style/IfUnlessModifier
