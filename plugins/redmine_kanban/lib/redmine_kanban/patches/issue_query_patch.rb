# frozen_string_literal: true

require_dependency 'issue_query'

module RedmineKanban
  module Patches
    module IssueQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method(:base_scope_without_kanban, :base_scope)
          alias_method(:base_scope, :base_scope_with_kanban)

          if Gem::Version.new(Redmine::VERSION.to_s) < Gem::Version.new('5.0.0')
            alias_method(:issues_without_kanban, :issues)
            alias_method(:issues, :issues_with_kanban_redmine_42)
          end

          # alias_method(:issue_ids_without_kanban, :issue_ids)
          # alias_method(:issue_ids, :issue_ids_with_kanban)

          alias_method(:available_filters_without_kanban_fields, :available_filters)
          alias_method(:available_filters, :available_filters_with_kanban_fields)


          add_available_column(
            QueryColumn.new(
              :size,
              caption: :label_issue_size,
              default_order: 'asc',
              sortable: "COALESCE((#{KanbanIssueSize.table_name}.sort_order), 0)"
            )
          )
        end
      end

      module InstanceMethods
        def base_scope_with_kanban
          base_scope_without_kanban.left_joins(:kanban_issue)
        end

        # rubocop:disable Style/OptionHash
        def issues_with_kanban_redmine_42(options = {})
          order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)
          # rubocop:disable Style/IfUnlessModifier
          # The default order of IssueQuery is issues.id DESC(by IssueQuery#default_sort_criteria)
          unless ["#{Issue.table_name}.id ASC", "#{Issue.table_name}.id DESC"].any? {|i| order_option.include?(i)}
            order_option << "#{Issue.table_name}.id DESC"
          end

          scope = base_scope.preload(:priority)
                            .where(statement)
                            .includes(([:status, :project, :kanban_issue] + (options[:include] || [])).uniq)
                            .where(options[:conditions])
                            .order(order_option)
                            .joins(joins_for_order_statement(order_option.join(',')))
                            .limit(options[:limit])
                            .offset(options[:offset])

          scope = scope.preload([:tracker, :author, :assigned_to, :fixed_version, :category, :attachments] & columns.map(&:name))
          scope = scope.preload(:custom_values) if has_custom_field_column?

          issues = scope.to_a
          if has_column?(:spent_hours)
            Issue.load_visible_spent_hours(issues)
          end
          if has_column?(:total_spent_hours)
            Issue.load_visible_total_spent_hours(issues)
          end
          if has_column?(:last_updated_by)
            Issue.load_visible_last_updated_by(issues)
          end
          if has_column?(:relations)
            Issue.load_visible_relations(issues)
          end
          if has_column?(:last_notes)
            Issue.load_visible_last_notes(issues)
          end
          # rubocop:enable Style/IfUnlessModifier
          issues
        rescue ActiveRecord::StatementInvalid => e
          raise(StatementInvalid.new(e.message))
        end
        # rubocop:enable Style/OptionHash

        def sql_for_block_reason_field(field, operator, value)
          "(#{sql_for_field(field, operator, value, KanbanIssue.table_name, 'block_reason', true)})"
        end

        def sql_for_kanban_issue_size_field(field, operator, value)
          sql_for_field(field, operator, value, KanbanIssue.table_name, 'size_id', false)
        end

        def available_filters_with_kanban_fields
          available_filters_without_kanban_fields
          add_available_filter('block_reason', type: :text, name: l(:label_board_locked))
          add_available_filter(
            'kanban_issue_size',
            type: :list_optional,
            name: l(:label_issue_size),
            values: KanbanIssueSize.get_all_ordered.map {|s| [s.name, s.id.to_s]}
          )
        end
      end
    end
  end
end

# rubocop:disable Style/IfUnlessModifier
unless IssueQuery.included_modules.include?(RedmineKanban::Patches::IssueQueryPatch)
  IssueQuery.send(:include, RedmineKanban::Patches::IssueQueryPatch)
end
# rubocop:enable Style/IfUnlessModifier
