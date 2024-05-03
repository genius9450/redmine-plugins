# frozen_string_literal: true

require_dependency 'queries_helper'

module RedmineKanban
  module Patches
    module QueriesHelperPatch
      def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do
          alias_method(:column_value_simple, :column_value)
          alias_method(:column_value, :column_value_extended)

          alias_method(:csv_value_simple, :csv_value)
          alias_method(:csv_value, :csv_value_extended)
        end
      end

      module InstanceMethods
        def column_value_extended(column, item, value)
          if value.is_a?(KanbanIssueSize)
            format_object(value.name)
          else
            column_value_simple(column, item, value)
          end
        end

        def csv_value_extended(column, item, value)
          if value.is_a?(KanbanIssueSize)
            format_object(value.name)
          else
            csv_value_simple(column, item, value)
          end
        end
      end
    end
  end
end

# rubocop:disable Style/IfUnlessModifier
unless QueriesHelper.included_modules.include?(RedmineKanban::Patches::QueriesHelperPatch)
  QueriesHelper.send(:include, RedmineKanban::Patches::QueriesHelperPatch)
end
# rubocop:enable Style/IfUnlessModifier
