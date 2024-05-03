# frozen_string_literal: true

scope 'questionlist' do
  get '/:issue_id', to: 'advanced_checklist#index'
  post '/:issue_id', to: 'advanced_checklist#create'
  patch '/:id', to: 'advanced_checklist#patch'
  put '/assign/:id', to: 'advanced_checklist#assign'
end

scope 'question' do
  get '/:questionlist_id', to: 'advanced_checklist#item_index'
  get '/:id/details', to: 'advanced_checklist#item_details'
  get '/assignees/:issue_id', to: 'advanced_checklist#item_assignees'
  post '/:questionlist_id', to: 'advanced_checklist#item_create'
  patch '/:id', to: 'advanced_checklist#item_patch'
end


