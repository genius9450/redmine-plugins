# frozen_string_literal: true

require_dependency 'issue_query'

module AdvancedChecklists
  module Patches

    module KanbanQueryPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
      end

      module InstanceMethods
        def sql_for_assigned_to_id_field(field, operator, value)
          sql = sql_for_field(field, operator, value, Issue.table_name, :assigned_to_id)
          if AdvancedChecklistSettings.is_respect_checklist_assigners_in_filter?
            case operator
            when '='
              checklist_items_sql = "#{Issue.table_name}.id IN " \
                                    "(SELECT DISTINCT(issue_id) FROM #{AdvancedChecklist.table_name} " \
                                    "LEFT JOIN #{AdvancedChecklistItem.table_name} ON #{AdvancedChecklistItem.table_name}.questionlist_id = #{AdvancedChecklist.table_name}.id " \
                                    "WHERE #{sql_for_boolean_field(AdvancedChecklist.table_name, 'deleted', '=', 0)} " \
                                    "AND #{sql_for_field(field, operator, value, AdvancedChecklistItem.table_name, :assigned_to_id)} " \
                                    "AND #{sql_for_boolean_field(AdvancedChecklistItem.table_name, 'done', '=', 0)} " \
                                    "AND #{sql_for_boolean_field(AdvancedChecklistItem.table_name, 'deleted', '=', 0)}))"
              sql = sql.insert(0, '(') << " OR #{checklist_items_sql}"
            else
              ''
            end
          end

          sql
        end

        def sql_for_boolean_field(table_name, field, operator, value)
          op = (operator == '=' ? 'IN' : 'NOT IN')
          va = value.to_i == 0 ? self.class.connection.quoted_false : self.class.connection.quoted_true
          "#{table_name}.#{field} #{op} (#{va})"
        end

      end
    end
  end
end

# rubocop:disable Style/IfUnlessModifier

unless IssueQuery.included_modules.include?(AdvancedChecklists::Patches::KanbanQueryPatch)
  IssueQuery.send(:include, AdvancedChecklists::Patches::KanbanQueryPatch)
end

if AdvancedChecklistSettings.is_kanban_installed? && !KanbanQuery.included_modules.include?(AdvancedChecklists::Patches::KanbanQueryPatch)
  KanbanQuery.send(:include, AdvancedChecklists::Patches::KanbanQueryPatch)
end
# rubocop:enable Style/IfUnlessModifier
