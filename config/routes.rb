Rails.application.routes.draw do

  root 'webview#home'

  get '/dashboard', to: 'webview#index'

  scope module: 'static_pages' do
    get 'about'
    get 'contact'
    get 'copyright'
    get 'developers'
    get 'help'
    get 'privacy'
    get 'share'
    get 'status'
    get 'terms'
  end

  mount OpenStax::Accounts::Engine, at: "/accounts"
  mount FinePrint::Engine => "/fine_print"

  use_doorkeeper

  apipie

  api :v1, :default => true do

    resources :users, only: [:index]
    resource :user, only: [] do
      get 'tasks', on: :collection
    end

    resource :user, only: [:show, :update, :destroy]

  end
  
  namespace 'admin' do
    get '/', controller: 'console', action: 'index'

    resources :administrators, only: [:index, :create, :destroy]

    resource :cron, only: [:update]

    resources :exceptions, only: [:show]

    resources :licenses

    resources :users, only: [:index] do
      member do
        put 'become'
        patch 'delete'
        patch 'undelete'
      end
    end
  end

  namespace :dev do
    resources :users, only: [:create] do
      post 'generate', on: :collection
    end
  end

  resource :user, only: [:show, :update, :destroy]

  match '/*other', via: [:get, :post, :put, :patch, :delete], to: 'webview#index'

end
