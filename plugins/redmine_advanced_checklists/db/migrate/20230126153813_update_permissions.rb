class UpdatePermissions < ActiveRecord::Migration[5.2]

  def change
    Setting.load_plugin_settings

    puts "Add project module Checklists to defaults" do
      Setting.default_projects_modules += ['advanced_checklists']
    end

    # Enable Rate for every project.
    puts "Enable modules Checklists for existing project" do
      projects = Project.all.to_a

      projects.each do |project|
        project.enable_module!(:advanced_checklists)
      end

      projects.length
    end
  end


end