# frozen_string_literal: true

module RedmineKanban
  module Hooks
    class ViewsIssuesHook < Redmine::Hook::ViewListener
      render_on :view_issues_form_details_bottom, :partial => 'issues/kanban_issues_fields'
      render_on :view_issues_show_details_bottom, :partial => 'issues/kanban_issues_labels'
    end
  end
end
