# frozen_string_literal: true

class KanbanIssueSize < ActiveRecord::Base
  self.table_name = 'kanban_issue_sizes'

  belongs_to :kanban_issue

  validates :name,
            length: {maximum: 20, too_long: '%{count} characters is the maximum allowed'},
            allow_blank: false

  before_destroy :check_for_related_issues

  def set_order(value)
    return if value == sort_order

    options = if value > sort_order
                {delta: -1, start: sort_order, end: value}
              else
                {delta: 1, start: value, end: sort_order}
              end
    sizes = KanbanIssueSize.where('sort_order BETWEEN ? AND ?', options[:start], options[:end])
                           .order(sort_order: :asc)
    sizes.to_a.each do |s|
      s.sort_order = s.id == id ? value : (s.sort_order + options[:delta])
      s.save!(touch: false)
    end
  end

  def self.get_all_ordered
    KanbanIssueSize.order(sort_order: :asc)
  end

private

  def check_for_related_issues
    i = Issue.where(kanban_issue: KanbanIssue.where(size: self))

    raise(StandardError.new(l(:error_denied_destroy_not_empty_size))) if i.count.positive?
  end
end
