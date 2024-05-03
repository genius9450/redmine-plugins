# frozen_string_literal: true

class AdvancedChecklist < ChecklistBase
  self.table_name = 'advanced_checklists'

  belongs_to :issue,
             class_name: 'Issue',
             foreign_key: 'issue_id',
             optional: false

  has_many :items,
           class_name: 'AdvancedChecklistItem',
           dependent: :destroy,
           foreign_key: 'questionlist_id'





  def editable?(user = User.current)
    return false if issue.closed?
    return true if user.admin?
    return false unless issue.visible?(user)
    return personal_editable?(user) if respond_to?(:personal_editable?)

    user.allowed_to?(:edit_checklists, issue.project)
  end

  def items
    AdvancedChecklistItem.where(questionlist: self, deleted: false).order(sort_order: :asc, id: :asc)
  end

  def length
    items.size
  end

  def assignable?(user)
    user = Principal.find(user.to_i) unless user.instance_of?(User)
    user.nil? || issue.assignable_users.include?(user)
  end

  def undone_items
    AdvancedChecklistItem.where(questionlist: self, deleted: false, done: false)
                         .order(sort_order: :asc, id: :asc)
  end

  def project
    issue.project
  end



private

end
