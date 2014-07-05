Rails.application.routes.draw do
  resources :arabic_roots

  resources :books

  root to: 'books#index'
  devise_for :users
  resources :users
end
