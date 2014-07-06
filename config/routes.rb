Rails.application.routes.draw do
  root 'pages#show'
  resources :pages
  get '/:name/:number', to: 'pages#show'
  get '/:search_string', to: 'pages#find'
end
