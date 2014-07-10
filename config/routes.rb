Rails.application.routes.draw do
  root                 to: 'pages#show'
  get  '/:book/:page', to: 'pages#show'
  post '/:book/:page', to: 'pages#show'
  get  '/:search',     to: 'pages#find'
  post '/pages',       to: 'pages#find'
  post '/books',       to: 'pages#find'
end
