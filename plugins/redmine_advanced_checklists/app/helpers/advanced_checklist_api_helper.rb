# frozen_string_literal: true

module AdvancedChecklistApiHelper
  # errors should be array of string
  def api_errors(errors = [])
    render(json: {errors: errors},
           status: :forbidden)
  end

  # errors should be array of string
  def api_one_error(error)
    render(json: {error: error},
           status: :forbidden)
  end

  def api_403(error = '')
    render(json: {error: error},
           status: :forbidden)
  end

  def api_validation_errors(objects)
    messages = Array.wrap(objects).map {|object| object.errors.full_messages}.flatten
    api_errors(messages.flatten)
  end

  def api_404(text = 'Not found')
    render(json: {error: text},
           status: :not_found)
  end

  def api_updated_at(updated_at)
    render(json: {updated_at: updated_at},
           status: :ok)
  end

  def api_answer(array)
    render(json: array,
           status: :ok)
  end

  def api_exception(exception)
    logger.error("ERROR(api_exception): #{exception.message}, trace: #{exception.backtrace.inspect}")
    render(json: {error: exception.message, trace: exception.backtrace},
           status: :forbidden)
  end

  def check_item_updated_at
    if params[:data][:updated_at].nil?
      api_one_error('updated_at required')
      return
    end

    updated_at = DateTime.parse(params[:data][:updated_at]).to_i
    api_one_error(l(:notice_issue_update_conflict)) if (updated_at - @checklist_item.updated_at.to_i).abs.positive?
  rescue TypeError
    api_one_error('updated_at wrong format')
  rescue StandardError => e
    api_exception(e)
  end

  def check_checklist_updated_at
    if params[:data][:updated_at].nil?
      api_one_error('updated_at required')
      return
    end

    updated_at = DateTime.parse(params[:data][:updated_at]).to_i
    api_one_error(l(:notice_issue_update_conflict)) unless updated_at == @checklist.updated_at.to_i
  rescue TypeError
    api_one_error('updated_at required')
  rescue StandardError => e
    api_exception(e)
  end

  def check_answer_updated_at
    if params[:data][:updated_at].nil?
      api_one_error('updated_at required')
      return
    end

    updated_at = DateTime.parse(params[:data][:updated_at]).to_i
    api_one_error(l(:notice_issue_update_conflict)) if (updated_at - @answer.updated_at.to_i).abs.positive?
  rescue TypeError
    api_one_error('updated_at wrong format')
  rescue StandardError => e
    api_exception(e)
  end

  def find_issue_by_id
    @issue = Issue.find(params[:issue_id])
    raise(Unauthorized) unless @issue.visible?

    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    api_404
  end

  def find_checklist_by_qid
    @checklist = AdvancedChecklist.find(params[:questionlist_id])
    @issue = @checklist.issue
    raise(Unauthorized) unless @issue.visible?

    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    api_404
  rescue StandardError => e
    api_exception(e)
  end

  def find_checklist_by_id
    @checklist = AdvancedChecklist.find(params[:id])
    @issue = @checklist.issue
    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    api_404
  end

  def find_checklist_item_by_id
    @checklist_item = AdvancedChecklistItem.find(params[:id])
    @issue = @checklist_item.questionlist.issue
    api_403 unless @issue.visible?

    @project = @issue.project
    raise(Unauthorized) if @checklist_item.questionlist.is_type_personal? && !@checklist_item.editable?(User.current)
  rescue ActiveRecord::RecordNotFound
    api_404
  end

end
