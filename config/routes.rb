# Try to list more often used routes first, although catch-all routes have to be at the end
Rails.application.routes.draw do

  # Home page, course picker, course dashboard and student enrollment
  scope controller: :webview do
    root action: :home

    # The routes below would be served by the webview catch-all route,
    # but we define them so we can use them as helpers that point to certain FE pages
    scope action: :index do

      # routes that are handled by the FE
      get :dashboard
      get :'course/:id', as: :course_dashboard
      get :'course/:course_id/task/:task_id', as: :student_task
      get :'course/:course_id/t/month/:date/plan/:task_id', as: :teacher_task_plan_review

      scope :enroll do
        get :':enroll_token(/:ignore)', as: :token_enroll,
                                        block_sign_up: false,
                                        straight_to_student_sign_up: true
        post :confirm, as: :confirm_token_enroll
      end
    end
  end

  # Static pages
  scope controller: :static_pages do
    get :about
    get :contact
    post :contact_form
    get :copyright
    get :developers
    get :help
    get :privacy
    get :share
    get :status
    get :'auth/failure', action: :omniauth_failure
    get :signup
  end

  # User information and remote log in/out
  namespace :auth do
    match :status, action: :cors_preflight_check, via: [:options]
    get :status
    match :popup, via: [:get, :post], as: :authenticate_via_popup
    get :logout, as: :logout_via_popup
  end

  # Short codes
  get :'@/:short_code(/:human_readable)', to: 'short_codes#redirect', as: :short_code

  # Terms of use/Privacy policy
  resources :terms, only: [:index] do
    collection do
      get :pose
      post :agree, as: :agree_to
    end
  end

  mount OpenStax::Accounts::Engine => :accounts
  mount FinePrint::Engine => :fine_print

  # All API routes
  api :v1, default: true do
    resources :users, only: [:index]
    resource :user, only: [:show] do
      get :tasks
      put :ui_settings
      patch 'tours/:tour_id', action: :record_tour_view
      resources :courses, only: [:index] do
        patch :student, to: 'students#update_self'
      end
    end

    resources :notifications, only: [:index]

    namespace :log do
      post :entry
    end

    resources :tasks, only: [:show, :destroy] do
      member do
        put :accept_late_work
        put :reject_late_work
      end

      resources :steps, controller: :task_steps, shallow: true, only: [:show, :update] do
        member do
          put :completed
          put :recovery
          put :refresh
        end
      end
    end

    namespace :cc do
      namespace :tasks do
        get :':cnx_book_id/:cnx_page_id', action: :show
        get :':course_id/:cnx_page_id/stats', action: :stats
      end
    end

    resources :courses, only: [:create, :show, :update] do
      member do
        get :'dashboard(/role/:role_id)', action: :dashboard
        get :'cc/dashboard(/role/:role_id)', action: :cc_dashboard
        get :roster
        post :clone

        scope :performance, controller: :performance_reports do
          get :'(/role/:role_id)', action: :index
          post :export
          get :exports
        end

        scope :practice, controller: :practices do
          get :'(/role/:role_id)', action: :show
          post :'(/role/:role_id)', action: :create
          post :'worst(/role/:role_id)', action: :create_worst
        end
      end

      scope controller: :guides do
        get :'guide(/role/:role_id)', action: :student
        get :teacher_guide, action: :teacher
      end

      resource :exercises, controller: :course_exercises, only: [:update] do
        get :'(/:pool_types)', action: :show
      end

      resources :task_plans, path: :plans, shallow: true, except: [:new, :edit] do
        member do
          get :stats
          get :review
          put :restore
        end
      end

      resources :students, shallow: true, except: [:index, :create] do
        put :undrop, on: :member
      end

      resources :teachers, shallow: true, only: [:destroy]

      resources :periods, shallow: true, only: [:create, :update, :destroy] do
        put :restore, on: :member
      end
    end

    namespace :pages do
      get :':uuid@:version', action: :get_page
      get :':uuid', action: :get_page
    end

    resources :ecosystems, only: [:index] do
      member do
        get :readings
        get :'exercises(/:pool_types)', action: :exercises
      end
    end

    resources :enrollment_changes, only: [:create] do
      put :approve, on: :member
      post :prevalidate, on: :collection
    end

    resources :offerings, only: [:index]

    resources :jobs, only: [:index, :show]

    match :'*all', to: 'api#options', via: [:options]
  end

  # Teacher enrollment
  scope to: 'courses#teach' do
    get :'teach/:teach_token(/:ignore)', as: :teach_course
    get :'courses/join/:teach_token', as: :deprecated_teach_course
  end

  # API docs
  apipie

  # All admin routes
  namespace :admin do
    scope controller: :console do
      root action: :index

      get :'raise(/:type)', action: :test_raise, as: :raise
    end

    resources :users, except: :destroy do
      member do
        post :become
        patch :delete
        patch :undelete
      end
      collection do
        get :info
      end
    end

    resources :administrators, only: [:index, :create, :destroy]

    resources :ecosystems, except: [:edit] do
      get :manifest, on: :member
    end

    resources :catalog_offerings, except: [:show]

    resources :courses, except: :show do
      member do
        post :students
        post :set_ecosystem
        post :set_catalog_offering
        post :teachers, controller: :teachers
        post :add_salesforce
        delete :remove_salesforce
        put :restore_salesforce
      end

      post :bulk_update, on: :collection

      resources :periods, shallow: true, except: :index do
        member do
          put :restore
          put :change_salesforce
        end
      end

      resources :students, only: [:index]
      resources :teachers, only: [:destroy], shallow: true
    end

    resources :schools, except: [:show]

    resources :districts, except: [:show]

    resources :notifications,  only: [:index, :create, :destroy]

    resources :targeted_contracts, except: [:show, :edit]

    resources :research_data, only: [:index, :create]

    resource :salesforce, only: [:show], controller: :salesforce do
      delete :destroy_user
      post :import_courses
      put :update_salesforce
    end

    mount RailsSettingsUi::Engine => :settings

    resource :cron, only: [:update]

    resources :exceptions, only: [:show]

    resources :jobs, only: [:index, :show]

    namespace :stats do
      get :courses
      get :excluded_exercises
      post :excluded_exercises_to_csv
      get :concept_coach
    end

    resources :tags, only: [:index, :edit, :update, :show]

    scope controller: :timecop do
      get :timecop
      put :reset_time
      post :freeze_time
      post :time_travel
    end
  end

  match '/auth/salesforce/callback', to: 'admin/salesforce#callback', via: [:get, :post]

  # All CS routes
  namespace :customer_service do
    root 'console#index'

    resources :users, only: [:index]

    resources :ecosystems, only: [:index] do
      get :manifest, on: :member
    end

    resources :courses, only: [:index, :show] do
      resources :periods, only: [:index]
      resources :students, only: [:index]
    end

    resources :targeted_contracts, only: [:index]

    resource :salesforce, only: [:show], controller: :salesforce do
      post :import_courses
    end

    resources :jobs, only: [:index, :show]

    namespace :stats do
      get :courses
      get :excluded_exercises
      get :concept_coach
    end

    resources :tags, only: [:index, :show]
  end

  # All CM routes
  namespace :content_analyst do
    root 'console#index'

    resources :ecosystems, except: [:edit] do
      get :manifest, on: :member
    end

    resources :jobs, only: [:show]
  end

  # Manage apps that use Tutor as an OAuth provider
  use_doorkeeper

  # Dev-only admin routes
  namespace :dev do
    resources :users, only: [:create] do
      post :generate, on: :collection
    end
  end

  # Catch-all frontend route
  match :'*other', to: 'webview#index', via: [:get, :post, :put, :patch, :delete]

end
