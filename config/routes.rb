Rails.application.routes.draw do
  root to: 'pages#index'

  resources :books do
    resources :pages
  end

  get '/:book_slug/:page', to: 'pages#show'
  get '/:query', to: 'pages#find'

  post '/change_dictionary', to: 'pages#show'
  post '/search', to: 'pages#find'
end
