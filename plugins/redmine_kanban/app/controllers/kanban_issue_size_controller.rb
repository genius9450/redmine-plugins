# frozen_string_literal: true

class KanbanIssueSizeController < ApplicationController
  before_action :find_kanban_issue_size,
                only: [:edit, :delete, :sort_order]

  def edit
    if request.method == 'POST'
      @size.name = params[:name]
      @size.sort_order = KanbanIssueSize.all.length if params[:id].nil?
      @size.save!

      return redirect_to(plugin_settings_path(id: 'redmine_kanban', tab: 'issue_size'))
    end

    @lbl = l((params[:id].nil? ? :title_issue_size_create : :title_issue_size_edit), name: @size.name)
    @url = {controller: :kanban_issue_size, action: :edit, id: @size.id}

    render('form')
  end

  def sort_order
    @size.set_order(params[:order][:position].to_i - 1)

    render(json: nil, status: :no_content)
  end

  def delete
    @size.destroy!

    redirect_to(plugin_settings_path(id: 'redmine_kanban', tab: 'issue_size'))
  end

private

  def find_kanban_issue_size
    @size = params[:id].nil? ? KanbanIssueSize.new : KanbanIssueSize.find(params[:id])
  end
end
