Rails.application.routes.draw do

  root 'webview#home'

  get '/dashboard', to: 'webview#index'

  scope module: 'static_pages' do
    get 'about'
    get 'contact'
    post 'contact_form'
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
    resources :jobs, only: [:index, :show]

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

    get 'user/courses', to: 'courses#index', as: :courses

    resources :guides, path: 'courses', only: [] do
      member do
        get 'guide(/role/:role_id)', action: :student
        get 'teacher_guide', action: :teacher
      end
    end

    resources :courses, only: [:show] do
      member do
        get 'readings'
        get 'exercises'
        get 'plans'
        get 'tasks'
        get 'dashboard(/role/:role_id)', action: :dashboard

        scope :performance, controller: :performance_reports do
          get '(/role/:role_id)', action: :index
          post 'export'
          get 'exports'
        end
      end

      post 'practice(/role/:role_id)' => 'practices#create'
      get 'practice(/role/:role_id)' => 'practices#show'

      resources :task_plans, path: '/plans', shallow: true, except: [:index, :new, :edit] do
        member do
          get 'stats'
          get 'review'
        end
      end

      resources :students, shallow: true, except: :create
    end

    scope 'pages', controller: :pages, action: :get_page do
      get ':uuid@:version'
      get ':uuid'
    end
  end

  namespace 'admin' do
    root to: 'console#index'

    resources :administrators, only: [:index, :create, :destroy]

    resources :courses, except: :destroy do
      member do
        post :students
        post :set_book
      end
      resources :periods, shallow: true
      resources :students, only: [:index], shallow: true
    end

    resources :districts

    resources :schools

    resource :cron, only: [:update]

    resources :exceptions, only: [:show]

    resources :licenses

    resources :jobs, only: [:index, :show]

    resources :users, except: :destroy do
      member do
        post 'become'
        patch 'delete'
        patch 'undelete'
      end
    end

    resources :tags, only: [:index, :edit, :update, :show]

    get :timecop, controller: :timecop, action: :index
    put :reset_time, controller: :timecop
    post :freeze_time, controller: :timecop
    post :time_travel, controller: :timecop

    resources :books, only: [:index] do
      collection do
        get :import
        post :import
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
