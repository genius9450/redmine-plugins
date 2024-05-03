[Website](https://redmine-kanban.com/) |
[Documentation](https://redmine-kanban.com/documentation) 

# Advanced Checklists Light

A free version of Advanced Checklists Redmine plugin - solution for managing complex tasks, with features such as employee assignment, change logging, and checklists items deadline tracking.
Plugin allows for efficient team collaboration through checkboxes commenting that ensures that no detail is overlooked with the ability to create and edit checklists without reloading the page.

## Main advantages of plugin

* Unlimited checklist items
* Editing by click
* assign every checklist item to different user

The plugin is fully compatible with our [other plugins](https://redmine-kanban.com/)

## Pro version

You can get acquainted with the pro-version of the plugin with additional features on [our website](https://redmine-kanban.com/)

## Get Started and Documentation

All plugins documentation is available [here](https://redmine-kanban.com/documentation).

### Install

1. Download plugin and copy plugin folder redmine_advanced_checklists to Redmine's plugins folder

2. Run migrations in redmine root folder.

`bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_advanced_checklists`

3. Restart server f.i.

`sudo /etc/init.d/apache2 restart`

### Configure
1. Configure user's roles  
   Plugin add permissions in "Checklists" block.
   
2. Enable modules "Checklists" for projects.

### Uninstall

1. go to redmine root folder

`bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_advanced_checklists VERSION=0`

2. go to plugins folder, delete plugin folder redmine_advanced_checklists

`rm -r redmine_advanced_checklists`

3. restart server f.i.

`sudo /etc/init.d/apache2 restart`

# error during installation

if you have error like 'Invalid route name, already in use:...' check that you have plugin redmine_kanban upper version 2.0.0  

### Requirements
Redmine 4.2, 5.0

Database: sqlite, mysql, postgresql 

## News & changelog

Latest news, updates are published on [Documentation page](https://redmine-kanban.com/documentation) and [our website](https://redmine-kanban.com/).

