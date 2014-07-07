Rails.application.routes.draw do
  root 'pages#show'
  resources :pages
  get '/:book_name/:page_id', to: 'pages#show'
  get '/:search_string', to: 'pages#find'
end
