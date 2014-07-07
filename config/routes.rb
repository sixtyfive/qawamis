Rails.application.routes.draw do
  root 'pages#show'
  get '/:book_name/:page_id', to: 'pages#show'
  get '/:search_string', to: 'pages#find'
  post '/pages', to: 'pages#find'
end
