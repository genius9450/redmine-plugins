class UpdatePermissions < ActiveRecord::Migration[5.2]

  def change
    Setting.load_plugin_settings
    Setting.plugin_redmine_kanban = {'kanban_show_in_app_menu' => 1, 'kanban_show_in_top_menu' => 1}

    puts "add project module Kanban" do
      Setting.default_projects_modules += ['kanban']
    end

    # Enable Kanban for every project.
    puts "Enable module Kanban for every project" do
      projects = Project.all.to_a

      projects.each do |project|
        project.enable_module!(:kanban)
      end

      projects.length
    end
  end


end