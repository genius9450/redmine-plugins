# frozen_string_literal: true

module AdvancedChecklists
  module Hooks
    class ViewsIssuesHook < Redmine::Hook::ViewListener
      render_on :view_issues_show_description_bottom,
                :partial => 'checklist/issue_checklist'
    end
  end
end
