# rubocop:disable Style/FrozenStringLiteralComment
ActiveSupport::Dependencies.explicitly_unloadable_constants = 'redmine_advanced_checklists' if Rails.env.development?
# rubocop:enable Style/FrozenStringLiteralComment

require 'redmine'

Redmine::Plugin.register(:redmine_advanced_checklists) do
  name 'Advanced checklists (Free)'
  author 'RK team'
  description 'Checklist plugin for Redmine'
  version '2.1.3'
  url 'https://redmine-kanban.com/'
  author_url 'https://redmine-kanban.com/'

  project_module :advanced_checklists do
    permission :edit_checklists,
               {questionlist: [:create, :update, :delete]}
    permission :view_advanced_checklists,
               {questionlist: [:index], question: [:index]}


  end

  menu :admin_menu,
       :advanced_checklists,
       {controller: 'settings', action: 'plugin', id: 'redmine_advanced_checklists'},
       caption: :label_advanced_checklists,
       html: {class: 'icon'}

  settings default: {empty: false},
           partial: 'settings/advanced_checklists/index'

end

# rubocop:disable Style/IfUnlessModifier
if Rails.configuration.respond_to?(:autoloader) && Rails.configuration.autoloader == :zeitwerk
  Rails.autoloaders.each {|loader| loader.ignore("#{File.dirname(__FILE__)}/lib")}
end
# rubocop:enable Style/IfUnlessModifier

require "#{File.dirname(__FILE__)}/lib/advanced_checklists"
