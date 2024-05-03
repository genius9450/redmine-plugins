# frozen_string_literal: true

require_dependency 'issue'

module AdvancedChecklists
  module Patches
    module IssuePatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          has_many(:questionlists, class_name: 'AdvancedChecklist', dependent: :destroy)
        end
      end

      module ClassMethods
        def load_visible_advanced_checklists(issues)
          return unless issues.any?

          questionslists = AdvancedChecklist.where(deleted: false, issue_id: issues.map(&:id)).all
          issues.each do |issue|
            issue.instance_variable_set(
              :@questionlists,
              questionslists.select {|c| c.issue_id == issue.id}
            )
          end
        end
      end

      module InstanceMethods
        def questionlists
          @questionlists ||= AdvancedChecklist.where(issue: self, deleted: false).order(id: :asc)
        end

        def can_add_checklist?(user = User.current)
          return false if closed?

          user.allowed_to?(:edit_checklists, project)
        end

        # rubocop:disable Lint/UselessAssignment
        def updated_on_now
          updated_on = Time.now
        end
        # rubocop:enable Lint/UselessAssignment
      end
    end
  end
end

# rubocop:disable Style/IfUnlessModifier
unless Issue.included_modules.include?(AdvancedChecklists::Patches::IssuePatch)
  Issue.send(:include, AdvancedChecklists::Patches::IssuePatch)
end
# rubocop:enable Style/IfUnlessModifier
