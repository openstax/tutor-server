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
  end

  get "terms/pose", to: "terms#pose", as: "pose_terms"
  post "terms/agree", to: "terms#agree", as: "agree_to_terms"
  get 'terms', to: 'terms#index'

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
        get 'dashboard(/role/:role_id)', action: :dashboard
        get 'plans'
        get 'tasks'

        scope :performance, controller: :performance_reports do
          get '(/role/:role_id)', action: :index
          post 'export'
          get 'exports'
        end

        scope :practice, controller: :practices do
          post '(/role/:role_id)', action: :create
          get '(/role/:role_id)', action: :show
        end
      end

      resources :task_plans, path: '/plans', shallow: true, except: [:index, :new, :edit] do
        member do
          get 'stats'
          get 'review'
        end
      end

      resources :students, shallow: true, except: :create

      resources :periods, shallow: true, only: [:create, :update]
    end

    resources :ecosystems, only: [:index] do
      member do
        get 'readings'
        get 'exercises(/:pool_types)', action: :exercises
      end
    end

    scope 'pages', controller: :pages, action: :get_page do
      get ':uuid@:version'
      get ':uuid'
    end
  end

  namespace 'admin' do
    root to: 'console#index'

    get 'raise(/:type)', to: 'console#test_raise', as: "raise"

    resources :administrators, only: [:index, :create, :destroy]

    resources :courses, except: [:show, :destroy] do
      member do
        post :students
        post :set_ecosystem
        post :teachers, controller: :teachers
      end
      resources :periods, shallow: true
      resources :students, only: [:index], shallow: true
      resources :teachers, only: [:destroy], shallow: true
    end

    resources :districts

    resources :schools

    resource :cron, only: [:update]

    resources :exceptions, only: [:show]

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

    resources :ecosystems, only: [:index] do
      collection do
        get :import
        post :import
      end
    end

    resources :targeted_contracts, except: [:show, :edit]
  end

  namespace 'customer_service' do
    root to: 'console#index'

    resources :courses, only: [:index, :show] do
      resources :periods, only: [:index], shallow: true
      resources :students, only: [:index], shallow: true
    end

    resources :jobs, only: [:index, :show]

    resources :users, only: :index

    resources :tags, only: [:index, :show]

    resources :ecosystems, only: [:index]

    resources :targeted_contracts, only: :index
  end

  namespace :dev do
    resources :users, only: [:create] do
      post 'generate', on: :collection
    end
  end

  match '/*other', via: [:get, :post, :put, :patch, :delete], to: 'webview#index'
end
