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
        member do
          put 'completed'
          put 'recovery'
          put 'refresh'
        end
      end
    end

    resources :courses, only: [:index] do
      member do
        get 'readings'
        get 'exercises'
        get 'plans'
        get 'tasks'
        get 'events(/role/:role_id)', action: :events
        get 'dashboard(/role/:role_id)', action: :dashboard
        post 'practice(/role/:role_id)', action: :practice
        get 'practice(/role/:role_id)', action: :practice
        get 'stats(/role/:role_id)', action: :stats
      end

      resources :task_plans, path: '/plans', shallow: true, except: [:index, :edit] do
        member do
          post 'publish'
          get 'stats'
          get 'review'
        end
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

    resources :users, except: :destroy do
      member do
        post 'become'
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
