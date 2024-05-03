# frozen_string_literal: true

class AdvancedChecklistController < ApplicationController
  include AdvancedChecklistApiHelper
  include AdvancedChecklistHelper

  before_action :find_issue_by_id,
                only: [:index, :create, :item_assignees]
  before_action :find_checklist_by_id,
                only: [:patch, :assign]
  before_action :find_checklist_by_qid,
                only: [:item_index, :item_create]
  before_action :check_checklist_updated_at,
                only: [:patch, :assign]
  before_action :find_checklist_item_by_id,
                only: [:item_details, :item_patch]
  before_action :check_item_updated_at,
                only: [:item_patch]

  def index
    data = []
    @issue.questionlists.each do |r|
      data.push(transform_checklist(r))
    end

    render(json: data)
  rescue StandardError => e
    api_exception(e)
  end

  def create
    type = case params[:list_type]
           when ChecklistBase::TYPE_USUAL
             raise(Unauthorized) unless @issue.can_add_checklist?(User.current)

             ChecklistBase::TYPE_USUAL
           else
             raise(l(:errors_unknown_list_type))
           end

    checklist = AdvancedChecklist.new
    checklist.title = params[:title]
    checklist.issue = @issue
    checklist.created_by = User.current
    checklist.list_type = type
    unless checklist.save
      render_validation_errors(checklist)
      return false
    end

    api_answer(transform_checklist(checklist))
  rescue StandardError => e
    api_exception(e)
  end

  def patch
    raise(Unauthorized) unless @checklist.editable?

    case params[:data][:action]
    when PATCH_ACTION_DELETE_CHECKLIST
      @checklist.set_deleted(true)
    when PATCH_ACTION_SET_TITLE_CHECKLIST
      @checklist.set_title(params[:data][:value])
    else
      api_one_error(l(:invalid_action_attribute))
      return
    end

    unless @checklist.save
      api_validation_errors(@checklist)
      return
    end

    render(json: {updatedAt: @checklist.updated_at})
  rescue StandardError => e
    api_exception(e)
  end

  def assign
    @checklist.undone_items.each do |r|
      if r.editable?
        r.set_assigned_to(params[:data][:value])
        r.save || render_validation_errors(r)
      end
    end

    @checklist.reload
    api_answer(transform_checklist(@checklist))
  rescue ActiveRecord::RecordNotFound => e
    api_404(e.message)
  rescue StandardError => e
    api_exception(e)
  end

  def item_index
    data = []
    @checklist.items.each do |r|
      data.push(transform_checklist_item(r))
    end

    render(json: data)
  rescue StandardError => e
    api_exception(e)
  end

  def item_details
    last_answers = is_true(params[:last])

    render(json: transform_checklist_item(@checklist_item, !last_answers))
  rescue StandardError => e
    api_exception(e)
  end

  def item_assignees
    data = []
    @issue.assignable_users.each do |r|
      data.push(transform_user(r))
    end

    render(json: data)
  rescue StandardError => e
    api_exception(e)
  end

  def item_create
    item = AdvancedChecklistItem.new
    item.title = params[:title]
    item.questionlist = @checklist
    item.created_by = User.current
    item.sort_order = AdvancedChecklistItem.where(questionlist: @checklist).length
    item.set_assigned_to(params[:assigned_to_id]) if params[:assigned_to_id]
    item.set_due_date(params[:due_date]) if params[:due_date]

    unless item.save
      api_validation_errors(item)
      return
    end

    render(json: transform_checklist_item(item))
  rescue StandardError => e
    api_exception(e)
  end

  def item_patch
    raise(Unauthorized) unless @checklist_item.editable?

    case params[:data][:action]
    when PATCH_ACTION_DELETE_ITEM
      @checklist_item.set_deleted(true)
    when PATCH_ACTION_COMPLETE_ITEM
      @checklist_item.set_completed(params[:data][:value])
    when PATCH_ACTION_SET_TITLE_ITEM
      @checklist_item.set_title(params[:data][:value])
    when PATCH_ACTION_SET_ASSIGNED_TO_ITEM
      @checklist_item.set_assigned_to(params[:data][:value])
    when PATCH_ACTION_SET_DUE_DATE_ITEM
      @checklist_item.set_due_date(params[:data][:value])
    when PATCH_ACTION_SET_SORT_ORDER_ITEM
      @checklist_item.set_order(params[:data][:value].to_i)
    else
      api_one_error(l(:invalid_action_attribute))
      return
    end

    unless @checklist_item.save
      api_validation_errors(@checklist_item)
      return
    end

    api_updated_at(@checklist_item.updated_at)
  rescue ActiveRecord::RecordNotFound
    api_404
  rescue StandardError => e
    api_exception(e)
  end
end
