# frozen_string_literal: true

module KanbanApiHelper
  # errors should be array of string
  def api_errors(errors = [], status = :forbidden)
    render(json: {errors: errors}, status: status)
  end

  def api_one_error(error, status = :forbidden)
    api_errors([error], status)
  end

  def api_403(error = '')
    api_one_error(error)
  end

  def api_404(error = 'Not found')
    api_one_error(error, :not_found)
  end

  def api_validation_errors(objects)
    full_messages = Array.wrap(objects).map {|object| object.errors.full_messages}
    messages = full_messages.flatten

    api_errors(messages.flatten)
  end

  def api_updated_at(updated_at)
    render(json: {:updated_at => updated_at}, status: :ok)
  end

  def api_answer(array)
    render(json: array, status: :ok)
  end

  def api_exception(exception)
    logger.error("ERROR(api_exception): #{exception.message}, trace: #{exception.backtrace.inspect}")
    render(json: {errors: [exception.message], trace: exception.backtrace}, status: :forbidden)
  end

  def build_kanban_query
    retrieve_query(KanbanQuery, true)
  end

  def check_issue_updated_at
    updated_on = DateTime.parse(params[:updated_on])
    api_one_error(l(:notice_issue_update_conflict)) unless updated_on.to_i == @issue.updated_on.to_i
  end

  def find_issue_by_id
    @issue = Issue.find(params[:issue_id])
    raise(Unauthorized) unless @issue.visible?

    @project = @issue.project
  rescue ActiveRecord::RecordNotFound
    api_404("Issue #{params[:issue_id]} not found")
  end

  def format_statuses(query)

    data = []
    query.get_statuses.each do |item|
        status = {
          id: item.id,
          name: item.name,
          color: Setting.plugin_redmine_kanban["status_color_#{item.id}"],
          is_closed: item.is_closed,
          is_group: false,
          substatuses: []
        }
        data << status
    end

    data
  end

end
