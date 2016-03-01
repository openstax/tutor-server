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
  mount OpenStax::Api::Engine, at: '/'
  mount FinePrint::Engine => "/fine_print"

  use_doorkeeper

  apipie


  # Fetch user information and log in/out in remotely
  scope :auth, controller: :auth do
    scope to: 'auth#cors_preflight_check', via: [:options] do
      match 'status'
    end
    get 'status'
    get 'logout', as: 'logout_via_popup'
    match 'popup', via: [:get, :post], as: 'authenticate_via_popup'
  end

  api :v1, default: true do
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

    namespace 'cc' do
      get 'tasks/:cnx_book_id/:cnx_page_id', to: 'tasks#show', as: :task
      get 'tasks/:course_id/:cnx_page_id/stats', to: 'tasks#stats', as: :task_stats
    end


    get 'user/courses', to: 'courses#index', as: :courses
    patch 'user/courses/:course_id/student', to: 'students#update_self'

    resources :guides, path: 'courses', only: [] do
      member do
        get 'guide(/role/:role_id)', action: :student
        get 'teacher_guide', action: :teacher
      end
    end

    resources :courses, only: [:show, :update] do
      member do
        get 'dashboard(/role/:role_id)', action: :dashboard
        get 'cc/dashboard(/role/:role_id)', action: :cc_dashboard
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

      resources :exercises, controller: :course_exercises, only: [:index, :update]

      resources :task_plans, path: '/plans', shallow: true, except: [:index, :new, :edit] do
        member do
          get 'stats'
          get 'review'
        end
      end

      get 'roster'

      resources :students, shallow: true, except: [:index, :create] do
        member do
          put 'undrop'
        end
      end

      resources :teachers, shallow: true, only: [:destroy]

      resources :periods, shallow: true, only: [:create, :update, :destroy]
    end

    resources :ecosystems, only: [:index] do
      member do
        get 'readings'
        get 'exercises(/:pool_types)', action: :exercises
      end
    end

    scope :pages, controller: :pages, action: :get_page do
      get ':uuid@:version'
      get ':uuid'
    end

    resources :enrollment_changes, only: :create do
      put 'approve', on: :member
      post 'prevalidate', on: :collection
    end

    namespace 'log' do
      post :entry
    end

    resources :notifications, only: [:index]
  end

  namespace 'admin' do
    root to: 'console#index'

    get 'raise(/:type)', to: 'console#test_raise', as: "raise"

    resources :administrators, only: [:index, :create, :destroy]

    resources :courses, except: :show do
      member do
        post :students
        post :set_ecosystem
        post :set_catalog_offering
        post :teachers, controller: :teachers
      end
      post :bulk_update, on: :collection
      resources :periods, shallow: true
      resources :students, only: [:index], shallow: true
      resources :teachers, only: [:destroy], shallow: true
    end

    resources :districts

    resources :schools

    resource :cron, only: [:update]

    resources :exceptions, only: [:show]

    resources :jobs, only: [:index, :show]
    resources :catalog_offerings, except: [:show]

    resources :users, except: :destroy do
      member do
        post 'become'
        patch 'delete'
        patch 'undelete'
      end
    end

    resources :tags, only: [:index, :edit, :update, :show]
    resources :notifications,  only: [:index, :create, :destroy]

    get :timecop, controller: :timecop, action: :index
    put :reset_time, controller: :timecop
    post :freeze_time, controller: :timecop
    post :time_travel, controller: :timecop

    resources :ecosystems, only: [:index, :destroy, :update] do
      collection do
        get :import
        post :import
      end
    end

    resources :targeted_contracts, except: [:show, :edit]

    resources :research_data, only: [:index, :create]

    resource :salesforce, only: [:show], controller: :salesforce do
      delete :destroy_user
      post :import_courses
      put :update_salesforce
    end

    resources :stats, only: [] do
      get :courses, on: :collection
      get :concept_coach, on: :collection
    end

    mount RailsSettingsUi::Engine, at: 'settings'
  end

  match '/auth/salesforce/callback', to: 'admin/salesforce#callback',
                                     via: [:get, :post]
  get '/auth/failure', to: 'static_pages#omniauth_failure'

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

    resource :salesforce, only: [:show], controller: :salesforce do
      post :import_courses
    end

    resources :stats, only: [] do
      get :courses, on: :collection
      get :concept_coach, on: :collection
    end
  end

  get '/courses/join/:join_token' => 'courses#join', as: :join_course
  get '/courses/:id', to: 'webview#index', as: :course_dashboard

  namespace :content_analyst do
    root to: 'console#index'

    resources :jobs, only: [:show]

    resources :ecosystems, only: [:index, :destroy, :update] do
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

  match '/*other', via: [:get, :post, :put, :patch, :delete], to: 'webview#index'
end
