# frozen_string_literal: true

class KanbanController < ApplicationController
  menu_item :redmine_kanban

  require 'json'

  include KanbanHelper
  include KanbanApiHelper
  include ProjectsHelper
  include QueriesHelper
  helper CustomFieldsHelper
  helper KanbanTranslateHelper
  helper CustomFieldsHelper


  accept_api_auth :get_issues, :get_issue

  before_action :find_optional_project,
                only: [:index, :get_issues, :set_issue_status]
  before_action :build_kanban_query,
                only: [:index, :get_issues, :set_issue_status]
  before_action :find_issue,
                only: [:set_issue_status, :get_issue, :patch]
  before_action :check_issue_updated_at,
                only: [:set_issue_status, :patch]

  def index
    @settings = get_board_settings
  end

  def get_issues
    params[:format] = :json
    respond_to do |format|
      format.html do
        render('get_issues', formats: :json, content_type: 'application/json')
      end
      format.json do
        render('get_issues', formats: :json, content_type: 'application/json')
      end
    end
  rescue StandardError => e
    api_exception(e)
  end

  def get_issue
    params[:format] = :json
    respond_to do |format|
      format.html do
        render(formats: :json, content_type: 'application/json')
      end
      format.json
    end
  end

  def set_issue_status
    raise(StandardError.new(l(:kanban_rejected_status))) unless User.current.allowed_to?(:edit_issues, @project)

      @issue.init_journal(User.current)
      @issue.safe_attributes = {status_id: params[:status_id].to_i}

      unless @issue.save
        render(json: {errors: @issue.errors.full_messages}, status: :forbidden)
        return
      end

    @items = @query.issues(limit: KanbanSettings.issues_limit)
    params[:format] = :json
    respond_to do |format|
      format.html do
        render('get_issues', formats: :json, content_type: 'application/json')
      end
      format.json do
        render('get_issues')
      end
    end
  rescue StandardError => e
    api_exception(e)
  end

  def patch
    @issue.init_journal(User.current)

    if params[:data][:block_reason]
      # if it was blocked do not change blocked_at
      @issue.blocked_at = Time.current if @issue.block_reason.nil?
      @issue.block_reason = params[:data][:block_reason].strip
    end

    @issue.blocked_at = params[:data][:blocked_at] if params[:data][:blocked_at]
    @issue.subject = params[:data][:subject].strip if params[:data][:subject]
    @issue.description = params[:data][:description].strip if params[:data][:description]

    params[:format] = :json

    unless @issue.save
      api_validation_errors(@issue)
      return
    end

    respond_to do |format|
      format.html do
        render('kanban/get_issue', formats: :json, content_type: 'application/json')
      end
      format.json
    end
  rescue StandardError => e
    api_exception(e)
  end
end
