# frozen_string_literal: true

require_dependency 'issue'

module RedmineKanban
  module Patches
    module IssuePatch
      def self.included(base)
        base.extend(ClassMethods)
        base.send(:include, InstanceMethods)
        base.class_eval do
          has_one(:kanban_issue, dependent: :destroy)

          # rubocop:disable Style/Lambda
          safe_attributes(
            'kanban_issue_attributes',
            if: lambda {|issue, user| issue.new_record? || user.allowed_to?(:edit_issues, issue.project)}
          )
          safe_attributes(
            'kanban_issue_size_attributes',
            if: lambda {|issue, user| issue.new_record? || user.allowed_to?(:edit_issues, issue.project)}
          )
          # rubocop:enable Style/Lambda

          accepts_nested_attributes_for(:kanban_issue, update_only: true)
        end
      end

      module ClassMethods
      end

      module InstanceMethods
        def kanban_issue
          super || build_kanban_issue
        end

        def day_in_state
          change_time = journals.joins(:details)
                                .where(
                                  journals: {journalized_id: id, journalized_type: 'Issue'},
                                  journal_details: {prop_key: 'status_id'}
                                )
                                .order('created_on DESC')
                                .first
          change_time.created_on
        rescue StandardError
          created_on
        end

        def block_reason
          @block_reason ||= kanban_issue&.block_reason
        end

        def block_reason=(text)
          kanban_issue.block_reason = text
        end

        def blocked_at
          @blocked_at ||= real_blocked_at
        end

        def blocked_at=(date)
          kanban_issue.blocked_at = date
        end

        def real_blocked_at
          return nil if block_reason.blank?

          journals.joins(:details)
                  .where("#{JournalDetail.table_name}.prop_key = 'block_reason'")
                  .where("#{JournalDetail.table_name}.value <> ''")
                  .where("#{JournalDetail.table_name}.value IS NOT NULL")
                  .where("(#{JournalDetail.table_name}.old_value = '' OR #{JournalDetail.table_name}.old_value IS NULL)")
                  .order(created_on: :desc)
                  .limit(1)
                  .first&.created_on
        end

        def sort_order
          kanban_issue.sort_order
        end

        def set_sort_order(order)
          kanban_issue.sort_order = order
        end

        def blocked_by_issues
          return @blocked_by_issues if @blocked_by_issues

          relation_blocks = relations.select {|ir| ir.relation_type == 'blocks' && !ir.issue_from.closed? && ir.issue_to.id == id}
          @blocked_by_issues = []
          relation_blocks.map do |relation|
            @blocked_by_issues << {
              id: relation.other_issue(self).id,
              subject: relation.other_issue(self).subject
            }
          end

          @blocked_by_issues
        end

        # Returns true if this issue is blocked by another issue that is still open
        def is_blocked_by_issues?
          !blocked_by_issues.empty?
        end

        def size
          @size ||= kanban_issue.size
        end

        def size=(size)
          kanban_issue.size = size
        end

        def size_id=(id)
          kanban_issue.size_id = id
        end

      end
    end
  end
end

# rubocop:disable Style/IfUnlessModifier
unless Issue.included_modules.include?(RedmineKanban::Patches::IssuePatch)
  Issue.send(:include, RedmineKanban::Patches::IssuePatch)
end
# rubocop:enable Style/IfUnlessModifier
