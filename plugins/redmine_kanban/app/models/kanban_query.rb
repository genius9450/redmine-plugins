# frozen_string_literal: false

class KanbanQuery < Query
  self.queried_class = Issue
  self.view_permission = :view_issues

  class_attribute :all_statuses

  self.available_columns = [
    QueryColumn.new(
      :id,
      sortable: "#{Issue.table_name}.id",
      default_order: 'desc',
      caption: '#',
      frozen: false,
      inline: false
    ),
    QueryColumn.new(
      :project,
      groupable: "#{Issue.table_name}.project_id",
      sortable: "#{Project.table_name}.id",
      inline: false
    ),
    QueryColumn.new(
      :tracker,
      sortable: "#{Tracker.table_name}.position",
      groupable: true,
      inline: false
    ),
    QueryColumn.new(
      :parent,
      sortable: ["#{Issue.table_name}.root_id", "#{Issue.table_name}.lft ASC"],
      default_order: 'desc',
      caption: :field_parent_issue,
      inline: false
    ),
    # QueryAssociationColumn.new(
    #   :parent,
    #   :subject,
    #   caption: :field_parent_issue_subject,
    #   inline: false
    # ),
    QueryColumn.new(
      :status,
      sortable: "#{IssueStatus.table_name}.position",
      groupable: false
    ),
    QueryColumn.new(
      :priority,
      sortable: "#{IssuePriority.table_name}.position",
      default_order: 'desc',
      groupable: true,
      # groupable: "#{Issue.table_name}.priority_id",
      inline: false
    ),
    QueryColumn.new(
      :subject,
      sortable: "#{Issue.table_name}.subject",
      inline: false
    ),
    QueryColumn.new(
      :author,
      sortable: -> {User.fields_for_order_statement('authors')},
      groupable: true, inline: false
    ),
    QueryColumn.new(
      :assigned_to,
      sortable: -> { User.fields_for_order_statement },
      groupable: "#{Issue.table_name}.assigned_to_id",
      inline: false
    ),
    QueryColumn.new(
      :updated_on,
      sortable: "#{Issue.table_name}.updated_on",
      default_order: 'desc',
      groupable: false,
      inline: false
    ),
    QueryColumn.new(
      :category,
      sortable: "#{IssueCategory.table_name}.name",
      groupable: true
    ),
    QueryColumn.new(
      :fixed_version,
      sortable: -> { Version.fields_for_order_statement },
      groupable: true
    ),
    # QueryColumn.new(
    #   :start_date,
    #   sortable: "#{Issue.table_name}.start_date",
    #   groupable: true
    # ),
    QueryColumn.new(
      :due_date,
      sortable: "#{Issue.table_name}.due_date",
      groupable: false,
      inline: false
    ),
    # QueryColumn.new(
    #   :estimated_hours,
    #   sortable: "#{Issue.table_name}.estimated_hours",
    #   totalable: true
    # ),
    QueryColumn.new(
      :total_estimated_hours,
      sortable: lambda {
        "COALESCE((SELECT SUM(estimated_hours) FROM #{Issue.table_name} subtasks " \
          "WHERE #{Issue.visible_condition(User.current).gsub(/\bissues\b/, 'subtasks')} " \
          "AND subtasks.root_id = #{Issue.table_name}.root_id " \
          "AND subtasks.lft >= #{Issue.table_name}.lft AND subtasks.rgt <= #{Issue.table_name}.rgt), 0)"
      },
      default_order: 'desc',
      inline: false
    ),
    # QueryColumn.new(
    #   :done_ratio,
    #   sortable: "#{Issue.table_name}.done_ratio",
    #   groupable: true
    # ),
    QueryColumn.new(
      :created_on,
      sortable: "#{Issue.table_name}.created_on",
      default_order: 'desc',
      groupable: false
    ),
  ]

  def initialize(attributes = nil, *args)
    super(attributes)

    options[:statuses] = available_statuses.select {|s| s.is_closed == false}.map(&:id)
    self.filters ||= KanbanSettings.default_query_filters
  end

  def build_from_params(params, defaults = {})
    super
    res = if params[:s].nil? || params[:s].empty?
            available_statuses.select {|c| c.is_closed == false}
          else
            available_statuses.select {|s| params[:s].include?(s.id.to_s)}
          end
    options[:statuses] = res.collect(&:id)

    if group_by_column&.name
      a = column_names
      a << group_by_column.name
      self.column_names = a
    end

    if params[:tag_id].present?
      if KanbanSettings.is_redmineup_tags_installed?
        f = [RedmineCrm::Tag.find_by(id: params[:tag_id]).try(:name)]
        add_filter('issue_tags', '=', f)
      end
      if KanbanSettings.is_additional_tags_installed?
        f = [ActsAsTaggableOn::Tag.find_by(id: params[:tag_id]).try(:name)]
        add_filter('tags', '=', f)
      end
    end



    self[:options] = options

    self
  end

  def available_columns
    return @available_columns if @available_columns

    @available_columns = self.class.available_columns.dup

    if User.current.allowed_to?(:view_time_entries, project, :global => true)
      # insert the columns after total_estimated_hours or at the end
      index = @available_columns.find_index {|column| column.name == :total_estimated_hours}
      index = (index ? index + 1 : -1)

      subselect = "SELECT SUM(hours) FROM #{TimeEntry.table_name} " \
                  "JOIN #{Project.table_name} ON #{Project.table_name}.id = #{TimeEntry.table_name}.project_id " \
                  "WHERE (#{TimeEntry.visible_condition(User.current)}) " \
                  "AND #{TimeEntry.table_name}.issue_id = #{Issue.table_name}.id"

      @available_columns.insert(
        index,
        QueryColumn.new(
          :spent_hours,
          sortable: "COALESCE((#{subselect}), 0)",
          default_order: 'desc',
          caption: :label_spent_time,
          totalable: true
        )
      )

      subselect = "SELECT SUM(hours) FROM #{TimeEntry.table_name} " \
                  "JOIN #{Project.table_name} ON #{Project.table_name}.id = #{TimeEntry.table_name}.project_id " \
                  "JOIN #{Issue.table_name} subtasks ON subtasks.id = #{TimeEntry.table_name}.issue_id " \
                  "WHERE (#{TimeEntry.visible_condition(User.current)}) " \
                  "AND subtasks.root_id = #{Issue.table_name}.root_id " \
                  "AND subtasks.lft >= #{Issue.table_name}.lft " \
                  "AND subtasks.rgt <= #{Issue.table_name}.rgt"

      @available_columns.insert(
        index + 1,
        QueryColumn.new(
          :total_spent_hours,
          sortable: "COALESCE((#{subselect}), 0)",
          default_order: 'desc',
          caption: :label_total_spent_time
        )
      )
    end

    if User.current.allowed_to?(:set_issues_private, nil, global: true) \
      || User.current.allowed_to?(:set_own_issues_private, nil, global: true)
      @available_columns << QueryColumn.new(
        :is_private,
        sortable: "#{Issue.table_name}.is_private",
        groupable: false
      )
    end

    disabled_fields = Tracker.disabled_core_fields(trackers).map {|field| field.sub(/_id$/, '')}
    disabled_fields << 'total_estimated_hours' if disabled_fields.include?('estimated_hours')
    @available_columns.reject! do |column|
      disabled_fields.include?(column.name.to_s)
    end

    @available_columns << QueryColumn.new(:tags, caption: :tags, inline: false) if KanbanSettings.is_redmineup_tags_installed?
    @available_columns << ::QueryTagsColumn.new if KanbanSettings.is_additional_tags_installed? \
      && AdditionalTags.setting?(:active_issue_tags) \
      && User.current.allowed_to?(:view_issue_tags, project, global: true)
    @available_columns << QueryColumn.new(:questionlist, caption: :label_checklist_plural, inline: false) if KanbanSettings.is_advanced_checklists_installed?

    @available_columns << QueryColumn.new(
      :kanban_issue_size,
      sortable: "#{KanbanIssueSize.table_name}.name",
      groupable: false,
      inline: false
    )

    @available_columns
  end

  def default_columns_names
    @default_columns_names ||= begin
      default_columns = [
        :subject,
        :assigned_to,
        :tracker,
        :id,
        :total_spent_hours,
        :total_estimated_hours,
        :updated_on,
        :due_date,
        :assigned_to,
        :author,
        :priority,
        :parent,
        :is_private,
      ]
      default_columns << :project unless project.present?
      default_columns << :tags if KanbanSettings.is_tags_installed?
      default_columns << :questionlist if KanbanSettings.is_advanced_checklists_installed?
      default_columns << :size if KanbanSettings.is_use_kanban_issue_sizes?
      default_columns
    end

    @default_columns_names
  end

  def available_board_columns
    col = [:status, :spent_hours, :estimated_hours, :fixed_version, :category, :created_on, :parent]
    available_columns.reject {|c| col.include?(c.name)}
  end

  def default_sort_criteria
    [['priority', 'desc'], ['id', 'asc']]
  end

  def statement
    filter = filters.delete('issue_tags')
    clauses = super || ''

    if KanbanSettings.is_redmineup_tags_installed? && filter
      filters['issue_tags'] = filter
      issues = Issue.where({})
      op = operator_for('issue_tags')
      issues = case op
               when '=', '!'
                 issues.tagged_with(values_for('issue_tags').clone, match_all: true)
               when '!*'
                 issues.joins(:tags).uniq
               else
                 issues.tagged_with(RedmineCrm::Tag.all.map(&:to_s), any: true)
               end
      compare = op.include?('!') ? 'NOT IN' : 'IN'
      ids_list  = issues.collect(&:id).push(0).join(',')

      clauses << ' AND ' unless clauses.empty?
      clauses << "( #{Issue.table_name}.id #{compare} (#{ids_list}) ) "
    end

    clauses
  end

  def base_scope
    statement_show_statuses = statuses.nil? || statuses.empty? ? '1 = 1' : "issues.status_id IN (#{statuses.join(', ')})"

    Issue.visible.joins(:status, :project).left_joins(:kanban_issue)
         .where(statement)
         .where(kanban_projects)
         .where(statement_show_statuses)
  end

  # Returns the issue count
  def issue_count
    base_scope.count
  rescue ActiveRecord::StatementInvalid => e
    raise(StatementInvalid.new(e.message))
  end

  # rubocop:disable Style/OptionHash
  def issues(options = {})
    order_option = [group_by_sort_order, (options[:order] || sort_clause)].flatten.reject(&:blank?)
    # The default order of IssueQuery is issues.id DESC(by IssueQuery#default_sort_criteria)
    # rubocop:disable Style/IfUnlessModifier
    unless ["#{Issue.table_name}.id ASC", "#{Issue.table_name}.id DESC"].any? {|i| order_option.include?(i)}
      order_option << "#{Issue.table_name}.id ASC"
    end
    # rubocop:enable Style/IfUnlessModifier


    scope = base_scope.preload(:priority)
                      .includes(([:status, :project, :kanban_issue] + (options[:include] || [])).uniq)
                      .where(options[:conditions])
                      .order(order_option)
                      .joins(joins_for_order_statement(order_option.join(',')))
                      .limit(options[:limit])
                      .offset(options[:offset])

    scope = scope.preload([:tracker, :author, :assigned_to, :fixed_version, :category, :attachments] & columns.map(&:name))
    scope = scope.preload(:custom_values) if has_custom_field_column?
    issues = scope.to_a

    has_column?(:spent_hours) && Issue.load_visible_spent_hours(issues)
    has_column?(:total_spent_hours) && Issue.load_visible_total_spent_hours(issues)
    has_column?(:last_updated_by) && Issue.load_visible_last_updated_by(issues)
    # has_column?(:relations) && Issue.load_visible_relations(issues)
    has_column?(:total_spent_hours) && Issue.load_visible_total_spent_hours(issues)
    has_column?(:questionlist) && Issue.load_visible_advanced_checklists(issues)


    Issue.load_visible_relations(issues)

    issues
  rescue ActiveRecord::StatementInvalid => e
    raise(StatementInvalid.new(e.message))
  end
  # rubocop:enable Style/OptionHash

  def kanban_projects
    # TODO need refactor: too many queries to db
    if project
      ids = [project.id]
      ids += project.descendants.map(&:id) if Setting.display_subprojects_issues?
      ids = EnabledModule.where(project_id: ids, name: 'kanban').map(&:project_id)
    else
      ids = EnabledModule.where(name: 'kanban').map(&:project_id)
    end
    ids.any? ? "#{Project.table_name}.id IN (#{ids.join(',')})" : '1 = 0'
  end

  # Kanban methods
  def statuses
    if use_custom_columns?
      get_used_statuses(get_custom_columns)
    else
      options[:statuses] || []
    end
  end

  # return entities
  def get_statuses
    available_statuses.select {|s| statuses.include?(s.id)}
  end

  def set_statuses=(ids)
    open_statuses = available_statuses.select {|s| s.is_closed == false}.map {|s| s.id.to_i}
    # save blank if all open statuses selected
    options[:statuses] = ids.count == open_statuses.count && (ids - open_statuses).empty? ? [] : ids
    self[:options] = options
  end

  def available_statuses
    @all_statuses ||= begin
      @all_statuses = project ? project.rolled_up_statuses.to_a : IssueStatus.all.sorted.to_a
    end

    @all_statuses
  end

  def has_status?(status)
    !!statuses.find {|c| c.to_i == status}
  end

  def groupable_columns
    method = Redmine::VERSION.to_s > '4.2' ? :groupable? : :groupable
    data = available_columns.select {|c| c.public_send(method) && !c.is_a?(QueryCustomFieldColumn)}
    data
  end

  def sql_for_block_reason_field(field, operator, value)
    db_table = KanbanIssue.table_name
    sql_for_field(field, operator, value, db_table, 'block_reason', true)
  end

  def sql_for_kanban_issue_size_field(field, operator, value)
    sql_for_field(field, operator, value, KanbanIssue.table_name, 'size_id', false)
  end


  # from IssueQuery class
  if Redmine::VERSION.to_s >= '5.0.0'
    has_many :projects,
             foreign_key: 'default_issue_query_id',
             dependent: :nullify,
             inverse_of: 'default_issue_query'

    after_update {projects.clear unless visibility == VISIBILITY_PUBLIC}

    scope :for_all_projects, -> {where(project_id: nil)}
  end

  def initialize_available_filters
    add_available_filter(
      'status_id',
      type: :list_status,
      values: -> {issue_statuses_values}
    )
    if project.nil?
      add_available_filter(
        'project_id',
        type: :list,
        values: -> {project_values}
      )
    end
    add_available_filter(
      'tracker_id',
      type: :list,
      values: trackers.collect {|s| [s.name, s.id.to_s]}
    )
    add_available_filter(
      'priority_id',
      type: :list,
      values: IssuePriority.all.collect {|s| [s.name, s.id.to_s]}
    )
    add_available_filter(
      'author_id',
      type: :list,
      values: -> {author_values}
    )
    add_available_filter(
      'assigned_to_id',
      type: :list_optional,
      values: -> {assigned_to_values}
    )
    add_available_filter(
      'member_of_group',
      type: :list_optional,
      values: -> {Group.givable.visible.collect {|g| [g.name, g.id.to_s]}}
    )
    add_available_filter(
      'assigned_to_role',
      type: :list_optional,
      values: -> {Role.givable.collect {|r| [r.name, r.id.to_s]}}
    )
    add_available_filter(
      'fixed_version_id',
      type: :list_optional,
      values: -> {fixed_version_values}
    )
    add_available_filter(
      'fixed_version.due_date',
      type: :date,
      name: l(:label_attribute_of_fixed_version, name: l(:field_effective_date))
    )
    add_available_filter(
      'fixed_version.status',
      type: :list,
      name: l(:label_attribute_of_fixed_version, name: l(:field_status)),
      values: Version::VERSION_STATUSES.map {|s| [l("version_status_#{s}"), s]}
    )
    if project
      add_available_filter(
        'category_id',
        type: :list_optional,
        values: -> {project.issue_categories.collect {|s| [s.name, s.id.to_s]}}
      )
    end

    add_available_filter('subject', type: :text)
    add_available_filter('description', type: :text)
    add_available_filter('notes', type: :text)
    add_available_filter('created_on', type: :date_past)
    add_available_filter('updated_on', type: :date_past)
    add_available_filter('closed_on', type: :date_past)
    add_available_filter('start_date', type: :date)
    add_available_filter('due_date', type: :date)
    add_available_filter('estimated_hours', type: :float)
    add_available_filter('spent_time', type: :float, label: :label_spent_time) if User.current.allowed_to?(:view_time_entries, project, global: true)
    add_available_filter('done_ratio', type: :integer)

    if User.current.allowed_to?(:set_issues_private, nil, global: true) \
      || User.current.allowed_to?(:set_own_issues_private, nil, global: true)
      add_available_filter(
        'is_private',
        type: :list,
        values: [[l(:general_text_yes), '1'], [l(:general_text_no), '0']]
      )
    end
    add_available_filter(
      'attachment',
      type: :text,
      name: l(:label_attachment)
    )
    add_available_filter(
      'attachment_description',
      type: :text,
      name: l(:label_attachment_description)
    )
    if User.current.logged?
      add_available_filter(
        'watcher_id',
        type: :list,
        values: -> {watcher_values}
      )
    end
    add_available_filter(
      'updated_by',
      type: :list,
      values: -> {author_values}
    )
    add_available_filter(
      'last_updated_by',
      type: :list,
      values: -> {author_values}
    )
    if project.nil? || !project.leaf?
      add_available_filter(
        'subproject_id',
        type: :list_subprojects,
        values: -> {subproject_values}
      )
      add_available_filter(
        'project.status',
        type: :list,
        name: l(:label_attribute_of_project, name: l(:field_status)),
        values: -> {project_statuses_values}
      )
    end

    add_custom_fields_filters(issue_custom_fields)
    add_associations_custom_fields_filters(:project, :author, :assigned_to, :fixed_version)

    IssueRelation::TYPES.each do |relation_type, options|
      add_available_filter(
        relation_type,
        type: :relation,
        label: options[:name],
        values: -> {all_projects_values}
      )
    end

    add_available_filter('parent_id', type: :tree, label: :field_parent_issue)
    add_available_filter('child_id', type: :tree, label: :label_subtask_plural)
    add_available_filter('issue_id', type: :integer, label: :label_issue)

    Tracker.disabled_core_fields(trackers).each do |field|
      delete_available_filter(field)
    end

    add_available_filter('block_reason', type: :text, name: l(:label_board_locked))
    add_available_filter(
      'kanban_issue_size',
      type: :list_optional,
      name: l(:label_issue_size),
      values: KanbanIssueSize.get_all_ordered.map {|s| [s.name, s.id.to_s]}
    )

    if KanbanSettings.is_redmineup_tags_installed?
      selected_tags = []
      if filters['issue_tags'].present?
        selected_tags = Issue.all_tags(project: project, open_only: RedmineupTags.settings['issues_open_only'].to_i == 1)
                             .where(name: filters['issue_tags'][:values])
                             .map {|c| [c.name, c.name]}
      end
      add_available_filter('issue_tags', type: :issue_tags, name: l(:tags), values: selected_tags)
    end

    initialize_tags_filter if KanbanSettings.is_additional_tags_installed? \
      && !available_filters.key?('tags') \
      && AdditionalTags.setting?(:active_issue_tags) \
      && User.current.allowed_to?(:view_issue_tags, project, global: true)
  end

  def sql_for_notes_field(field, operator, value)
    subquery = "SELECT 1 FROM #{Journal.table_name} " \
               "WHERE #{Journal.table_name}.journalized_type='Issue' " \
               "AND #{Journal.table_name}.journalized_id=#{Issue.table_name}.id " \
               "AND (#{sql_for_field(field, operator.sub(/^!/, ''), value, Journal.table_name, 'notes')}) " \
               "AND (#{Journal.visible_notes_condition(User.current, skip_pre_condition: true)})"
    "#{/^!/.match?(operator) ? 'NOT EXISTS' : 'EXISTS'} (#{subquery})"
  end

  def sql_for_updated_by_field(field, operator, value)
    neg = operator == '!' ? 'NOT' : ''
    subquery = "SELECT 1 FROM #{Journal.table_name} " \
               "WHERE #{Journal.table_name}.journalized_type='Issue' " \
               "AND #{Journal.table_name}.journalized_id=#{Issue.table_name}.id " \
               "AND (#{sql_for_field(field, '=', value, Journal.table_name, 'user_id')}) " \
               "AND (#{Journal.visible_notes_condition(User.current, skip_pre_condition: true)})"
    "#{neg} EXISTS (#{subquery})"
  end

  def sql_for_last_updated_by_field(field, operator, value)
    neg = operator == '!' ? 'NOT' : ''
    subquery = "SELECT 1 FROM #{Journal.table_name} sj " \
               "WHERE sj.journalized_type = 'Issue' AND sj.journalized_id=#{Issue.table_name}.id " \
               "AND (#{sql_for_field(field, '=', value, 'sj', 'user_id')}) " \
               "AND sj.id IN (SELECT MAX(#{Journal.table_name}.id) FROM #{Journal.table_name} " \
               "WHERE #{Journal.table_name}.journalized_type='Issue' " \
               "AND #{Journal.table_name}.journalized_id=#{Issue.table_name}.id " \
               "AND (#{Journal.visible_notes_condition(User.current, :skip_pre_condition => true)}))"
    "#{neg} EXISTS (#{subquery})"
  end

  def sql_for_spent_time_field(field, operator, value)
    first = value.first.to_f
    second = value.second.to_f
    sql_op = case operator
             when '=', '>=', '<='
               "#{operator} #{first}"
             when '><'
               "BETWEEN #{first} AND #{second}"
             when '*'
               '> 0'
             when '!*'
               '= 0'
             else
               nil
             end
    return nil if sql_op.nil?

    "COALESCE(( SELECT ROUND(CAST(SUM(hours) AS DECIMAL(30,3)), 2) FROM #{TimeEntry.table_name} " \
      "WHERE issue_id = #{Issue.table_name}.id), 0) #{sql_op}"
  end

  def sql_for_watcher_id_field(field, operator, value)
    db_table = Watcher.table_name
    me, others = value.partition {|id| ['0', User.current.id.to_s].include?(id)}
    sql = if others.any?
            "SELECT #{Issue.table_name}.id FROM #{Issue.table_name} " \
              "INNER JOIN #{db_table} ON #{Issue.table_name}.id = #{db_table}.watchable_id AND #{db_table}.watchable_type = 'Issue' " \
              "LEFT OUTER JOIN #{Project.table_name} ON #{Project.table_name}.id = #{Issue.table_name}.project_id " \
              "WHERE (#{sql_for_field(field, '=', me, db_table, 'user_id')}) " \
              "OR (#{Project.allowed_to_condition(User.current, :view_issue_watchers)} " \
              "AND #{sql_for_field(field, '=', others, db_table, 'user_id')})"
          else
            "SELECT #{db_table}.watchable_id FROM #{db_table} " \
              "WHERE #{db_table}.watchable_type='Issue' AND " \
              "#{sql_for_field(field, '=', me, db_table, 'user_id')}"
          end
    op = operator == '=' ? 'IN' : 'NOT IN'
    "#{Issue.table_name}.id #{op} (#{sql})"
  end

  def sql_for_member_of_group_field(field, operator, value)
    if operator == '*' # Any group
      groups = Group.givable
      operator = '=' # Override the operator since we want to find by assigned_to
    elsif operator == '!*'
      groups = Group.givable
      operator = '!' # Override the operator since we want to find by assigned_to
    else
      groups = Group.where(:id => value).to_a
    end
    groups ||= []

    members_of_groups = groups.inject([]) do |user_ids, group|
      user_ids + group.user_ids + [group.id]
    end.uniq.compact.sort.collect(&:to_s)

    sql = sql_for_field('assigned_to_id', operator, members_of_groups, Issue.table_name, 'assigned_to_id', false)
    "(#{sql})"
  end

  def sql_for_assigned_to_role_field(field, operator, value)
    case operator
    when '*', '!*' # Member / Not member
      sw = operator == '!*' ? 'NOT' : ''
      nl = operator == '!*' ? "#{Issue.table_name}.assigned_to_id IS NULL OR" : ''
      "(#{nl} #{Issue.table_name}.assigned_to_id #{sw} IN (SELECT DISTINCT #{Member.table_name}.user_id " \
        "FROM #{Member.table_name} " \
        "WHERE #{Member.table_name}.project_id = #{Issue.table_name}.project_id))"
    when '=', '!'
      role_cond =
        if value.any?
          v = value.collect {|val| "'#{self.class.connection.quote_string(val)}'"}.join(',')
          "#{MemberRole.table_name}.role_id IN (#{v})"
        else
          '1 = 0'
        end
      sw = operator == '!' ? 'NOT' : ''
      nl = operator == '!' ? "#{Issue.table_name}.assigned_to_id IS NULL OR" : ''
      "(#{nl} #{Issue.table_name}.assigned_to_id #{sw} IN (SELECT DISTINCT #{Member.table_name}.user_id " \
        "FROM #{Member.table_name}, #{MemberRole.table_name} " \
        "WHERE #{Member.table_name}.project_id = #{Issue.table_name}.project_id " \
        "AND #{Member.table_name}.id = #{MemberRole.table_name}.member_id AND #{role_cond}))"
    else
      ''
    end
  end

  def sql_for_fixed_version_status_field(field, operator, value)
    where = sql_for_field(field, operator, value, Version.table_name, 'status')
    version_id_scope = project ? project.shared_versions : Version.visible
    version_ids = version_id_scope.where(where).pluck(:id)

    nl = operator == '!' ? "#{Issue.table_name}.fixed_version_id IS NULL OR" : ''
    "(#{nl} #{sql_for_field('fixed_version_id', '=', version_ids, Issue.table_name, 'fixed_version_id')})"
  end

  def sql_for_fixed_version_due_date_field(field, operator, value)
    where = sql_for_field(field, operator, value, Version.table_name, 'effective_date')
    version_id_scope = project ? project.shared_versions : Version.visible
    version_ids = version_id_scope.where(where).pluck(:id)

    nl = operator == '!*' ? "#{Issue.table_name}.fixed_version_id IS NULL OR" : ''
    "(#{nl} #{sql_for_field('fixed_version_id', '=', version_ids, Issue.table_name, 'fixed_version_id')})"
  end

  def sql_for_is_private_field(field, operator, value)
    op = operator == '=' ? 'IN' : 'NOT IN'
    va =
      value.map do |v|
        v == '0' ? self.class.connection.quoted_false : self.class.connection.quoted_true
      end.uniq.join(',')
    "#{Issue.table_name}.is_private #{op} (#{va})"
  end

  def sql_for_attachment_field(field, operator, value)
    case operator
    when '*', '!*'
      e = (operator == '*' ? 'EXISTS' : 'NOT EXISTS')
      "#{e} (SELECT 1 FROM #{Attachment.table_name} a " \
        "WHERE a.container_type = 'Issue' AND a.container_id = #{Issue.table_name}.id)"
    when '~', '!~'
      c = sql_contains('a.filename', value.first)
      e = (operator == '~' ? 'EXISTS' : 'NOT EXISTS')
      "#{e} (SELECT 1 FROM #{Attachment.table_name} a " \
        "WHERE a.container_type = 'Issue' AND a.container_id = #{Issue.table_name}.id AND #{c})"
    when '^', '$'
      c = sql_contains('a.filename', value.first, (operator == '^' ? :starts_with : :ends_with) => true)
      "EXISTS (SELECT 1 FROM #{Attachment.table_name} a " \
        "WHERE a.container_type = 'Issue' AND a.container_id = #{Issue.table_name}.id AND #{c})"
    else
      ''
    end
  end

  def sql_for_attachment_description_field(field, operator, value)
    cond_description = "a.description IS NOT NULL AND a.description <> ''"
    c =
      case operator
      when '*', '!*'
        operator == '*' ? cond_description : "NOT (#{cond_description})"
      when '~', '!~'
        cop = operator == '~' ? '' : "#{cond_description} AND "
        cop + sql_contains('a.description', value.first, match: operator == '~')
      when '^', '$'
        sql_contains('a.description', value.first, (operator == '^' ? :starts_with : :ends_with) => true)
      else
        '1=0'
      end
    "EXISTS (SELECT 1 FROM #{Attachment.table_name} a " \
      "WHERE a.container_type = 'Issue' AND a.container_id = #{Issue.table_name}.id AND #{c})"
  end

  def sql_for_parent_id_field(field, operator, value)
    case operator
    when '='
      # accepts a comma separated list of ids
      ids = value.first.to_s.scan(/\d+/).map(&:to_i).uniq
      if ids.present?
        "#{Issue.table_name}.parent_id IN (#{ids.join(',')})"
      else
        '1 = 0'
      end
    when '~'
      root_id, lft, rgt = Issue.where(:id => value.first.to_i).pick(:root_id, :lft, :rgt)
      if root_id && lft && rgt
        "#{Issue.table_name}.root_id = #{root_id} AND #{Issue.table_name}.lft > #{lft} AND #{Issue.table_name}.rgt < #{rgt}"
      else
        '1 = 0'
      end
    when '!*'
      "#{Issue.table_name}.parent_id IS NULL"
    when '*'
      "#{Issue.table_name}.parent_id IS NOT NULL"
    else
      ''
    end
  end

  def sql_for_child_id_field(field, operator, value)
    case operator
    when '='
      # accepts a comma separated list of child ids
      child_ids = value.first.to_s.scan(/\d+/).map(&:to_i).uniq
      ids = Issue.where(:id => child_ids).pluck(:parent_id).compact.uniq
      if ids.present?
        "#{Issue.table_name}.id IN (#{ids.join(',')})"
      else
        '1 = 0'
      end
    when '~'
      root_id, lft, rgt = Issue.where(:id => value.first.to_i).pick(:root_id, :lft, :rgt)
      if root_id && lft && rgt
        "#{Issue.table_name}.root_id = #{root_id} AND #{Issue.table_name}.lft < #{lft} AND #{Issue.table_name}.rgt > #{rgt}"
      else
        '1 = 0'
      end
    when '!*'
      "#{Issue.table_name}.rgt - #{Issue.table_name}.lft = 1"
    when '*'
      "#{Issue.table_name}.rgt - #{Issue.table_name}.lft > 1"
    else
      ''
    end
  end

  def sql_for_updated_on_field(field, operator, value)
    case operator
    when '!*'
      "#{Issue.table_name}.updated_on = #{Issue.table_name}.created_on"
    when '*'
      "#{Issue.table_name}.updated_on > #{Issue.table_name}.created_on"
    else
      sql_for_field('updated_on', operator, value, Issue.table_name, 'updated_on')
    end
  end

  def sql_for_issue_id_field(field, operator, value)
    if operator == '='
      # accepts a comma separated list of ids
      ids = value.first.to_s.scan(/\d+/).map(&:to_i)
      if ids.present?
        "#{Issue.table_name}.id IN (#{ids.join(',')})"
      else
        '1 = 0'
      end
    else
      sql_for_field('id', operator, value, Issue.table_name, 'id')
    end
  end

  # rubocop:disable Style/OptionHash
  def sql_for_relations(field, operator, value, options = {})
    relation_options = IssueRelation::TYPES[field]
    return relation_options unless relation_options

    relation_type = field
    join_column = 'issue_from_id'
    target_join_column = 'issue_to_id'
    if relation_options[:reverse] || options[:reverse]
      relation_type = relation_options[:reverse] || relation_type
      join_column, target_join_column = target_join_column, join_column
    end
    sql =
      case operator
      when '*', '!*'
        op = (operator == '*' ? 'IN' : 'NOT IN')
        "#{Issue.table_name}.id #{op} " \
          "(SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} " \
          "FROM #{IssueRelation.table_name} " \
          "WHERE #{IssueRelation.table_name}.relation_type = " \
          "'#{self.class.connection.quote_string(relation_type)}')"
      when '=', '!'
        op = operator == '=' ? 'IN' : 'NOT IN'
        "#{Issue.table_name}.id #{op} " \
          "(SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} " \
          "FROM #{IssueRelation.table_name} " \
          "WHERE #{IssueRelation.table_name}.relation_type = " \
          "'#{self.class.connection.quote_string(relation_type)}' " \
          "AND #{IssueRelation.table_name}.#{target_join_column} = #{value.first.to_i})"
      when '=p', '=!p', '!p'
        op = operator == '!p' ? 'NOT IN' : 'IN'
        comp = operator == '=!p' ? '<>' : '='
        "#{Issue.table_name}.id #{op} " \
          "(SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} " \
          "FROM #{IssueRelation.table_name}, #{Issue.table_name} relissues " \
          "WHERE #{IssueRelation.table_name}.relation_type = " \
          "'#{self.class.connection.quote_string(relation_type)}' " \
          "AND #{IssueRelation.table_name}.#{target_join_column} = relissues.id " \
          "AND relissues.project_id #{comp} #{value.first.to_i})"
      when '*o', '!o'
        op = operator == '!o' ? 'NOT IN' : 'IN'
        "#{Issue.table_name}.id #{op} " \
          "(SELECT DISTINCT #{IssueRelation.table_name}.#{join_column} " \
          "FROM #{IssueRelation.table_name}, #{Issue.table_name} relissues " \
          "WHERE #{IssueRelation.table_name}.relation_type = " \
          "'#{self.class.connection.quote_string(relation_type)}' " \
          "AND #{IssueRelation.table_name}.#{target_join_column} = relissues.id AND relissues.status_id IN " \
          "(SELECT id FROM #{IssueStatus.table_name} " \
          "WHERE is_closed = #{self.class.connection.quoted_false}))"
      end
    if relation_options[:sym] == field && !options[:reverse]
      sqls = [sql, sql_for_relations(field, operator, value, reverse: true)]
      sql = sqls.join(['!', '!*', '!p', '!o'].include?(operator) ? ' AND ' : ' OR ')
    end
    "(#{sql})"
  end

  def sql_for_project_status_field(field, operator, value, options = {})
    sql_for_field(field, operator, value, Project.table_name, 'status')
  end
  # rubocop:enable Style/OptionHash

  def find_assigned_to_id_filter_values(values)
    Principal.visible.where(:id => values).map {|p| [p.name, p.id.to_s]}
  end

  # rubocop:disable Style/Alias
  alias :find_author_id_filter_values :find_assigned_to_id_filter_values
  # rubocop:enable Style/Alias

  IssueRelation::TYPES.each_key do |relation_type|
    alias_method "sql_for_#{relation_type}_field".to_sym, :sql_for_relations
  end

  # rubocop:disable Style/IfUnlessModifier
  def joins_for_order_statement(order_options)
    joins = [super]

    if order_options
      if order_options.include?('authors')
        joins << "LEFT OUTER JOIN #{User.table_name} authors ON authors.id = #{queried_table_name}.author_id"
      end
      if order_options.include?('users')
        joins << "LEFT OUTER JOIN #{User.table_name} ON #{User.table_name}.id = #{queried_table_name}.assigned_to_id"
      end
      if order_options.include?('last_journal_user')
        joins << "LEFT OUTER JOIN #{Journal.table_name} " \
                 "ON #{Journal.table_name}.id = (SELECT MAX(#{Journal.table_name}.id) " \
                 "FROM #{Journal.table_name} " \
                 "WHERE #{Journal.table_name}.journalized_type = 'Issue' " \
                 "AND #{Journal.table_name}.journalized_id = #{Issue.table_name}.id " \
                 "AND #{Journal.visible_notes_condition(User.current, skip_pre_condition: true)}) " \
                 "LEFT OUTER JOIN #{User.table_name} last_journal_user " \
                 "ON last_journal_user.id = #{Journal.table_name}.user_id"
      end
      if order_options.include?('versions')
        joins << "LEFT OUTER JOIN #{Version.table_name} " \
                 "ON #{Version.table_name}.id = #{queried_table_name}.fixed_version_id"
      end
      if order_options.include?('issue_categories')
        joins << "LEFT OUTER JOIN #{IssueCategory.table_name} " \
                 "ON #{IssueCategory.table_name}.id = #{queried_table_name}.category_id"
      end
      if order_options.include?('trackers')
        joins << "LEFT OUTER JOIN #{Tracker.table_name} " \
                 "ON #{Tracker.table_name}.id = #{queried_table_name}.tracker_id"
      end
      if order_options.include?('enumerations')
        joins << "LEFT OUTER JOIN #{IssuePriority.table_name} " \
                 "ON #{IssuePriority.table_name}.id = #{queried_table_name}.priority_id"
      end
    end

    joins.any? ? joins.join(' ') : nil
  end
  # rubocop:enable Style/IfUnlessModifier
  # END FROM issueQuery

  def use_custom_columns?
    !!options[:use_custom_columns]
  end

end
