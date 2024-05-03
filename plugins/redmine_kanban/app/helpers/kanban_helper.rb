# frozen_string_literal: true

module KanbanHelper
  include QueriesHelper
  include IssuesHelper

  include ActionView::Helpers::DateHelper
  include AdvancedChecklistHelper if KanbanSettings.is_advanced_checklists_installed?


  # Renders issue parents recursively
  def render_issue_parents(issue, api, tree)
    if issue.parent.nil?
      api.parents(tree) if tree.length.positive?
    else
      parent = issue.parent
      p = {id: parent.id, subject: parent.subject}
      p[:tracker] = {id: parent.tracker_id, name: parent.tracker.name} unless parent.tracker.nil?
      p[:status] = {id: parent.status_id, name: parent.status.name, is_closed: parent.status.is_closed} unless parent.status.nil?

      p[:child] = tree if tree.length.positive?
      tree = p
      render_issue_parents(parent, api, tree)
    end
  end

  def available_statuses_tags(query)
    tags = ''.html_safe
    query.available_statuses.each do |status|
      checkbox = check_box_tag('s[]', status.id, query.has_status?(status.id), id: status.name.to_s) + " #{status.name}"
      tags << content_tag('label', checkbox, class: 'inline')
    end

    tags
  end

  def available_kanban_columns_tags(query)
    tags = ''.html_safe
    query.available_board_columns.each do |column|
      tags << content_tag(
        'label',
        check_box_tag('c[]', column.name.to_s, query.has_column?(column), id: nil) + " #{column.caption}",
        class: 'inline'
      )
    end

    tags
  end

  def to_arr(query)
    return {query_id: query.id} if query.id

    f = []
    op = {}
    v = {}
    if query.filters.present?
      query.filters.each do |field, filter|
        f << field
        op[field.to_s] = filter[:operator]
        v[field] = []
        filter[:values].each do |value|
          v[field] << value
        end
      end
    end

    r = {
      set_filter: '1',
      sort: query.sort_criteria.to_param,
      f: f,
      op: op,
      v: v,
      group_by: query.group_by,
      c: query.columns.map(&:name)
    }
    r[:s] = query.statuses.map(&:to_s) if query.respond_to?(:statuses)

    r
  end

  def user_name_or_anonymous(user)
    user.nil? ? l(:label_user_anonymous) : user.name
  end

  def transform_user(record)
    u = {
      id: record.id,
      type: record.type,
      name: user_name_or_anonymous(record)
    }
    avatar = avatar(record, {size: 40})
    u[:avatar] = avatar if avatar.length > 1

    u
  end

  def get_show_card_properties(query)
    # rubocop:disable Lint/UselessAssignment
    # rubocop:disable Style/RedundantAssignment
    show_card_properties = query.columns.map do |column|
      v = column.name
      v
    end
    # rubocop:enable Lint/UselessAssignment
    # rubocop:enable Style/RedundantAssignment
    show_card_properties
  end

  def render_issue_on_board(issue, api)
    api.id(issue.id)
    api.status(issue_kanban_column(@query, issue)) unless issue.status.nil?
    api.subject(issue.subject)
    api.block_reason(issue.kanban_issue&.block_reason)
    api.blocked_at(issue.kanban_issue&.blocked_at)
    api.updated_on(issue.updated_on)
    # end required fields

    api.updated_on(issue.updated_on) if @query.has_column?(:updated_on)
    api.subject(issue.subject) if @query.has_column?(:subject)
    api.is_private(issue.is_private?) if @query.has_column?(:is_private)
    api.created_on(issue.created_on) if @query.has_column?(:created_on)
    # @TODO
    api.author(user_name_or_anonymous(issue.author)) if @query.has_column?(:author)

    api.tracker(id: issue.tracker_id, name: issue.tracker.name) if @query.has_column?(:tracker) && !issue.tracker.nil?
    api.project(id: issue.project_id, name: issue.project.name) if @query.has_column?(:project) && !issue.project.nil?
    api.priority(id: issue.priority_id, name: issue.priority.name) if @query.has_column?(:priority) && !issue.priority.nil?
    api.category(id: issue.category_id, name: issue.category.name) if @query.has_column?(:category) && !issue.category.nil?
    api.fixed_version(id: issue.fixed_version_id, name: issue.fixed_version.name) if @query.has_column?(:fixed_version) && !issue.fixed_version.nil?

    # rubocop:disable Style/IfUnlessModifier
    if !issue.disabled_core_fields.include?('due_date') && @query.has_column?(:due_date)
      api.due_date(issue.due_date)
      api.due_date_human(issue_due_date_details(issue))
    end

    if !issue.disabled_core_fields.include?('estimated_hours') && @query.has_column?(:total_estimated_hours)
      api.total_estimated_hours(issue.total_estimated_hours)
    end

    if User.current.allowed_to?(:view_time_entries, issue.project) && @query.has_column?(:total_spent_hours)
      api.total_spent_hours(issue.total_spent_hours.round(1))
    end

    if @query.has_column?(:parent) && !issue.parent_issue_id.nil?
      render_issue_parents(issue, api, {})
    end

    if !issue.disabled_core_fields.include?('assigned_to_id') && @query.has_column?(:assigned_to) && !issue.assigned_to_id.nil?
      api.assigned_to(transform_user(issue.assigned_to))
    end
    # rubocop:enable Style/IfUnlessModifier

    api.blocked_by_issues(issue.blocked_by_issues) if issue.is_blocked_by_issues?

    if KanbanSettings.is_advanced_checklists_installed? && @query.has_column?(:questionlist) && issue.project.module_enabled?(AdvancedChecklistSettings::MODULE_NAME) \
      && respond_to?(:transform_checklist_info)
      api.question_lists(issue.questionlists.map {|checklist| transform_checklist_info(checklist)})
    end

    render_issue_tags(issue, api) if KanbanSettings.is_tags_installed? && @query.has_column?(:tags)

    api.size(id: issue.size.id, name: issue.size.name) if @query.has_column?(:kanban_issue_size) && !issue.size.nil?

  end

  def get_board_settings
    {
      id: @project&.identifier,
      query: request.GET.empty? ? to_arr(@query) : request.GET,
      statuses: format_statuses(@query),
      show_card_properties: get_show_card_properties(@query)
    }
  end

  def self.is_true(value)
    return false unless value.present?

    ['true', 'yes', 'y', '1', 1, true].include?(value)
  end

  def issue_kanban_column(query, issue)
    {
      id: issue.status_id,
      name: issue.status.name,
      is_closed: issue.status.is_closed
    }
  end
end
