[Website](https://redmine-kanban.com/) |
[Documentation](https://redmine-kanban.com/documentation)

# Kanban Board Light

A free version of plugin for Redmine that simplify the way you manage your Agile projects with advanced and user-friendly Kanban Board!
Transform your workflow, visualize progress and prioritize tasks effortlessly with this powerful tool.

## Main advantages of plugin

* Detail view of issue on a modal board
* Quick filters
* Drag and drop on board
* External block display

The plugin is fully compatible with our [other plugins](https://redmine-kanban.com/)

### Install

1. Delete old plugins version if it exists
```shell
cd redmine/plugins
rm -r redmine_kanban
```

2. Copy plugin folder redmine_kanban to plugins/

3. Run migrations in redmine root folder.
```shell
bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_kanban
```

3. Restart server f.i.
```shell
sudo /etc/init.d/apache2 restart
```

### Configure
1. Go to Administration -> Kanban

2. Configure user's roles. Plugin add permissions in "Kanban" block.

3. Enable modules "Kanban" for projects.

## Pro version

You can get acquainted with the pro-version of the plugin with additional features on [our website](https://redmine-kanban.com/)

### Uninstall

1. go to redmine root folder
```shell
bundle exec rake redmine:plugins:migrate RAILS_ENV=production NAME=redmine_kanban VERSION=0
```

2. go to plugins folder, delete plugin folder redmine_kanban
```shell
rm -r redmine_kanban
```

3. restart server f.i.
```shell
sudo /etc/init.d/apache2 restart
```


### Requirements
Redmine 4.2, 5.0

Database: sqlite, mysql, postgresql 

## News & changelog

Latest news, updates are published on [Documentation page](https://redmine-kanban.com/documentation) and [our website](https://redmine-kanban.com/).
