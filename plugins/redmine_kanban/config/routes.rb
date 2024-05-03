# frozen_string_literal: true

get '/projects/:project_id/kanban/board', to: 'kanban#index', as: 'project_kanban_board'

scope 'kanban' do
  get '/board', to: 'kanban#index', as: 'common_kanban_board'
  post '/set_issue_status/', to: 'kanban#set_issue_status'
  post '/:project_id/set_issue_status/', to: 'kanban#set_issue_status'
  post '/issues/', to: 'kanban#get_issues'
  post '/:project_id/issues', to: 'kanban#get_issues'
  get '/issue/:id', to: 'kanban#get_issue'
  patch '/issue/:id', to: 'kanban#patch'
end

scope 'kanban_query' do
  post '/favorites', to: 'kanban_query_enterprise#add_to_favorites', as: 'post_kanban_query_add_to_fav'
  delete '/favorites', to: 'kanban_query_enterprise#remove_from_favorites', as: 'delete_kanban_query_remove_from_fav'
end

resources :kanban_query, :except => [:show] do
  delete '/:id', to: 'kanban_query#destroy', constraints: {id: /\d+/}, as: 'kanban_query_destroy'
end

scope 'projects/:project_id/kanban_query' do
  get '/new', to: 'kanban_query#new', as: 'kanban_project_query_new'
  post '/new', to: 'kanban_query#create'
  get '/:id', to: 'kanban_query#edit', as: 'kanban_project_query_edit'
  patch '/:id', to: 'kanban_query#update', as: 'kanban_project_query_update'
  put '/:id', to: 'kanban_query#update', as: 'kanban_project_query_put'
end

scope 'kanban/issue-size' do
  match '', to: 'kanban_issue_size#edit', as: 'kanban_issue_size_create', via: [:get, :post]
  match '/:id', to: 'kanban_issue_size#edit', as: 'kanban_issue_size_edit', via: [:get, :post]
  put '/:id', to: 'kanban_issue_size#sort_order', as: 'kanban_issue_size_sort_order'
  delete '/:id', to: 'kanban_issue_size#delete', as: 'kanban_issue_size_delete'
end

scope 'issues' do
  get '/:id/status', to: 'kanban_journal_details#status', as: 'kanban_journal_details_status', constraints: IssueStatusHistoryRouteConstraint.new
  get '/:id/block-history', to: 'kanban_journal_details#block_history', as: 'kanban_journal_details_block_history'
end


