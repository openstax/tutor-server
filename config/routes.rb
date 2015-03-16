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

    resource :user, only: [:show] do
      get 'tasks', on: :collection
    end

    resources :tasks, only: [:show] do
      resources :steps, controller: :task_steps, shallow: true, only: [:show, :update] do
        put 'completed', on: :member
      end
    end

    resources :courses, only: [] do
      get 'readings', on: :member
      get 'plans', on: :member
      resources :task_plans, path: '/plans', shallow: true, except: [:index, :edit] do
        post 'publish', on: :member
      end
    end
  end

  namespace 'admin' do
    root to: 'console#index'

    resources :administrators, only: [:index, :create, :destroy]

    resources :courses, except: :destroy

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
