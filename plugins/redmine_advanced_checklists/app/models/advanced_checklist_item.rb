# frozen_string_literal: true

class AdvancedChecklistItem < ChecklistItemBase
  LAST_ANSWERS_LIMIT = 3

  self.table_name = 'advanced_checklist_items'

  belongs_to :questionlist,
             class_name: 'AdvancedChecklist',
             foreign_key: 'questionlist_id',
             inverse_of: :items
  belongs_to :completed_by,
             class_name: 'User',
             foreign_key: 'completed_by_id'



  def set_assigned_to(data)
    if data.nil? || data.to_i == 0
      self.assigned_to = nil
    else
      user = Principal.find(data.to_i)
      Watcher.create(:watchable => questionlist.issue, :user => user) if user.instance_of?(User)
      self.assigned_to = user
    end
  end

  def set_completed(data)
    self.done = data
    if data == true
      self.completed_by = User.current
      self.completed_at = Time.now
    else
      self.completed_by = nil
      self.completed_at = nil
    end
  end

  def editable?(user = User.current)
    return false if questionlist.issue.closed?
    return true if user.admin?
    return false unless questionlist.issue.visible?(user)
    return editable_extra?(user) if respond_to?(:editable_extra?)

    user.allowed_to?(:edit_checklists, checklist.issue.project)
  end

  def is_assigned_to_required?
    return false unless questionlist

    questionlist.is_type_personal?
  end

  def issue
    questionlist.issue
  end

  def set_due_date(data)
    self.due_date = data
  end

  def get_due_date
    due_date || nil
  end

  def editable_extra?(user = User.current)

    if questionlist.is_type_personal?
      user.allowed_to?(:manage_any_checklist_assigned, questionlist.issue.project) \
          || created_by == user \
          || assigned_to == user \
          || questionlist.created_by == user \
          || (!assigned_to.nil? && user.group_ids.include?(assigned_to.id))
    else
      user.allowed_to?(:edit_checklists, questionlist.issue.project)
    end
  end


private


end
