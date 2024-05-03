# frozen_string_literal: true

module AdvancedChecklistHelper
  PATCH_ACTION_DELETE_CHECKLIST = 'questionlist.delete'
  PATCH_ACTION_SET_TITLE_CHECKLIST = 'questionlist.set_title'

  PATCH_ACTION_DELETE_ITEM = 'question.delete'
  PATCH_ACTION_COMPLETE_ITEM = 'question.complete'
  PATCH_ACTION_SET_TITLE_ITEM = 'question.set_title'
  PATCH_ACTION_SET_ASSIGNED_TO_ITEM = 'question.set_assigned_to'
  PATCH_ACTION_SET_DUE_DATE_ITEM = 'question.set_due_date'
  PATCH_ACTION_SET_SORT_ORDER_ITEM = 'question.set_order'

  PATCH_ACTION_EDIT_CONTENT_ANSWER = 'question_answer.edit_content'
  PATCH_ACTION_DELETE_ANSWER = 'question_answer.delete'

  def transform_checklist(record, all_answers = false)
    checklist = {
      id: record.id,
      editable: record.editable?,
      title: record.title,
      sort_order: record.sort_order,
      updated_at: record.updated_at,
      created_by: user_name_or_anonymous(record.created_by),
      deleted: record.deleted,
      list_type: record.list_type,
      tasks: []
    }

    record.items.each do |item|
      checklist[:tasks] << transform_checklist_item(item, all_answers)
      checklist[:flag_not_all_assigned] = true if AdvancedChecklistSettings.is_all_should_be_assigned? && !item.done && item.assigned_to.nil?
    end

    checklist
  end

  def transform_checklist_info(record)
    res = {
      :id => record.id,
      :title => record.title
    }

    questions_total = 0
    questions_completed = 0
    assignees = []
    record.items.each do |r|
      questions_total += 1
      if r.done
        questions_completed += 1
      else
        assignees << transform_user(r.assigned_to) unless r.assigned_to.nil? || assignees.detect {|f| f['id'] == r.assigned_to.id}
        res[:flag_not_all_assigned] = true if AdvancedChecklistSettings.is_all_should_be_assigned? && r.done != true && r.assigned_to.nil?
      end
    end
    res[:questions_total] = questions_total
    res[:questions_completed] = questions_completed
    res[:assignees] = assignees
    res[:deleted] = record.deleted
    res[:list_type] = record.list_type

    res
  end

  def transform_checklist_item(record, all_answers = false)
    item = {
      id: record.id,
      editable: record.editable?,
      issue_id: record.issue&.id,
      questionlist_id: record.questionlist&.id,
      title: record.title,
      done: record.done,
      completed_at: record.completed_at,
      completed_by: record.completed_by&.name,
      sort_order: record.sort_order,
      updated_at: record.updated_at,
      created_by: user_name_or_anonymous(record.created_by)
    }
    item[:assigned_to] = transform_user(record.assigned_to) unless record.assigned_to.nil?


    item
  end

  def transform_user(record)
    return nil if record.nil?

    user = {
      :id => record.id,
      :type => record.type,
      :name => user_name_or_anonymous(record)
    }

    user
  end


  def user_name_or_anonymous(user)
    user.nil? ? l(:label_user_anonymous) : user.name
  end

  def user_name_or_anonymous_by_id(user_id)
    user = Principal.find_by(:id => user_id)
    user_name_or_anonymous(user)
  end

  def user_or_anonymous(user)
    user.nil? ? User.anonymous : user
  end

  def is_true(value)
    return false unless value.present?

    ['true', 'yes', 'y', '1', 1, true].include?(value)
  end
end
