# frozen_string_literal: true

require "#{File.dirname(__FILE__)}/redmine_kanban/patches/issue_patch"
require "#{File.dirname(__FILE__)}/redmine_kanban/patches/issue_query_patch"
require "#{File.dirname(__FILE__)}/redmine_kanban/patches/setting_patch"
require "#{File.dirname(__FILE__)}/redmine_kanban/hooks/views_issues_hook"
require "#{File.dirname(__FILE__)}/redmine_kanban/patches/settings_controller_patch"
require "#{File.dirname(__FILE__)}/redmine_kanban/patches/issues_controller_patch"
require "#{File.dirname(__FILE__)}/redmine_kanban/patches/queries_helper_patch"

