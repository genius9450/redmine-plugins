# frozen_string_literal: true

class KanbanIssue < ActiveRecord::Base
  belongs_to :issue

  validates :block_reason,
            length: {maximum: 1000, too_long: '%{count} characters is the maximum allowed'},
            allow_blank: true

  before_save :update_fields

  belongs_to :size,
             class_name: 'KanbanIssueSize',
             foreign_key: 'size_id'

  def size_id=(id)
    self.size = id.present? ? KanbanIssueSize.find(id) : nil
  end

private

  # rubocop:disable Style/GuardClause
  def update_fields
    if block_reason_changed?
      block_reason.strip!
      if block_reason.present? || block_reason_was.present?
        issue.init_journal(User.current)

        issue.current_journal.details << JournalDetail.new(
          :property => 'attr',
          :prop_key => 'block_reason',
          :old_value => block_reason_was,
          :value => block_reason
        )
      end

      if block_reason_was.present?
        block_reason.present? || (self.blocked_at = nil)
      else
        blocked_at.present? || (self.blocked_at = Time.current)
      end
    end

    if size_id_changed?
      issue.init_journal(User.current)
      issue.current_journal.details << JournalDetail.new(
        property: 'attr',
        prop_key: 'kanban_issue_size',
        old_value: (size_id_was.nil? ? nil : KanbanIssueSize.find(size_id_was)&.name),
        value: (size_id.nil? ? nil : KanbanIssueSize.find(size_id)&.name)
      )
    end

  end
  # rubocop:enable Style/GuardClause
end
