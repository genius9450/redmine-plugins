# frozen_string_literal: true

class IssueStatusHistoryRouteConstraint
  def matches?(_request)
    !KanbanSettings.is_redmineup_agile_installed?
  end
end
