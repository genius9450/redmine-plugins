# frozen_string_literal: true

class KanbanJournalDetailsController < ApplicationController
  before_action :find_issue

  helper :issues

  def block_history
    @history_collector = KanbanIssueBlockHistoryCollector.new(@issue)

    respond_to do |format|
      format.html
    end
  end

  def status
    @statuses_collector = KanbanIssueStatusesCollector.new(@issue)

    respond_to do |format|
      format.html
    end
  end
end
