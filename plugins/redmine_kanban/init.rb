# rubocop:disable Style/FrozenStringLiteralComment
ActiveSupport::Dependencies.explicitly_unloadable_constants = 'redmine_kanban' if Rails.env.development?
# rubocop:enable Style/FrozenStringLiteralComment

require 'redmine'

Redmine::Plugin.register(:redmine_kanban) do
  name 'Kanban board plugin (Free)'
  author 'RK team'
  description 'Kanban board plugin for redmine'
  version '2.2.0'
  url 'https://redmine-kanban.com'
  author_url 'https://redmine-kanban.com'

  project_module :kanban do
    permission :view_kanban,
               {kanban: [:index, :get_issues, :get_issue, :set_issue_status], kanban_query: [:index], kanban_table: [:index, :issues]}
  end

  menu :project_menu,
       :redmine_kanban,
       {controller: 'kanban', action: 'index'},
       caption: :label_kanban,
       after: :activity,
       param: :project_id

  menu :top_menu,
       :redmine_kanban,
       {controller: 'kanban', action: 'index', project_id: nil},
       caption: :label_kanban,
       first: true,
       if: proc { User.current.allowed_to?({controller: 'kanban', action: 'index'}, nil, {global: true}) && Setting.plugin_redmine_kanban['kanban_show_in_top_menu'].to_i.positive? }

  menu :application_menu,
       :redmine_kanban,
       {controller: 'kanban', action: 'index'},
       caption: :label_kanban,
       if: proc { User.current.allowed_to?({controller: 'kanban', action: 'index'}, nil, {global: true}) && Setting.plugin_redmine_kanban['kanban_show_in_app_menu'].to_i.positive? }

  menu :admin_menu,
       :redmine_kanban,
       {controller: 'settings', action: 'plugin', id: 'redmine_kanban'},
       caption: :project_module_kanban,
       html: {class: 'icon'}

  settings :default => {:empty => true},
           :partial => 'settings/kanban/index'
end

# rubocop:disable Style/IfUnlessModifier
if Rails.configuration.respond_to?(:autoloader) && Rails.configuration.autoloader == :zeitwerk
  Rails.autoloaders.each {|loader| loader.ignore("#{File.dirname(__FILE__)}/lib")}
end
# rubocop:enable Style/IfUnlessModifier

require "#{File.dirname(__FILE__)}/lib/redmine_kanban"
