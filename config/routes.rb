Rails.application.routes.draw do
  mount Importmap::Engine, at: "_"

  get "/favicon.ico", to: redirect(ActionController::Base.helpers.asset_path("favicon.ico"))

  root to: 'pages#index'

  resources :books do
    resources :pages
  end

  post '/change_dictionary', to: 'pages#show'
  post '/search', to: 'pages#find'

  get '/:book_slug/:page', to: 'pages#show', constraints: {book_slug: /[a-z0-9_]+/, page: /\-?\d+/}
  get '/:query', to: 'pages#find', constraints: ->(request){request.path.exclude?('.')}

  match '*unmatched', to: 'application#not_found', via: :all
end
