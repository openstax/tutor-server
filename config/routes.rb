# Try to list more often used routes first, although catch-all routes have to be at the end
Rails.application.routes.draw do

  mount OpenStax::Salesforce::Engine, at: '/admin/salesforce'
  OpenStax::Salesforce.set_top_level_routes(self)

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
    end

    scope :enroll do
      # this is handled by the FE
      get :'start/:enroll_token', action: :index, as: :start_enrollment, block_sign_up: false, straight_to_student_sign_up: true
      # we render this to display a splash screen before login/signup
      get :':enroll_token(/*ignored)', as: :token_enroll, action: :enroll
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
    get :stubbed_payments
    get :browser_upgrade
  end

  get :non_student_signup,
      to: redirect('/dashboard?block_sign_up=false&straight_to_sign_up=true')

  resource :pardot, controller: :pardot, only: [] do
    get :toa
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

  resources :purchases, only: [:show]

  mount OpenStax::Accounts::Engine => :accounts
  mount FinePrint::Engine => :fine_print

  # API docs
  apipie

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

    resources :updates, only: [:index]

    namespace :log do
      post :entry
      post 'event/onboarding/:code', action: :onboarding_event
    end

    resources :purchases, only: [:index] do
      member do
        put :check
        put :refund
      end

      if !IAm.real_production?
        collection do
          post 'fake', action: 'create_fake'
        end
      end
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

    resources :metatasks, only: [:show, :destroy] do
      # resources :metasteps, controller: :metatask_steps, shallow: true, only: [:show, :update]
    end

    resources :research_surveys, only: [:update]

    namespace :cc do
      namespace :tasks do
        get :':cnx_book_id/:cnx_page_id', action: :show
        get :':course_id/:cnx_page_id/stats', action: :stats
      end
    end

    resources :courses, only: [:create, :show, :update] do
      member do
        get :'dashboard', action: :dashboard
        get :'cc/dashboard', action: :cc_dashboard
        get :roster
        post :clone

        scope :performance, controller: :performance_reports do
          get :index
          post :export
          get :exports
        end

        scope :practice, controller: :practices do
          get :show
          post :create
          post :worst, action: :create_worst
        end
      end
      post :dates, on: :collection

      resources :notes, path: 'notes/:chapter.:section'
      get :highlighted_sections, controller: :notes

      scope controller: :guides do
        get :guide, action: :student
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
        member do
          put :restore
          put :teacher_student
        end
      end
    end

    resources :ecosystems, only: [:index] do
      member do
        get :readings
        get :'exercises(/:pool_types)', action: :exercises
      end

      get 'pages/*cnx_id', to: 'pages#show', format: false
    end

    resources :enrollment, only: [:create] do
      put :approve, on: :member
      post :prevalidate, on: :collection
      get :choices, on: :member
    end

    resources :offerings, only: [:index]

    resources :jobs, only: [:index, :show]

    get 'terms', to: 'terms#index'
    put 'terms/:ids', to: 'terms#sign'

    namespace :lms do
      resources :courses, only: [:show] do
        member do
          put :push_scores
          post :pair
        end
      end
    end

    match :'*all', to: 'api#options', via: [:options]

  end # end of API scope

  # Teacher enrollment
  scope to: 'courses#teach' do
    get :'teach/:teach_token(/:ignore)', as: :teach_course
    get :'courses/join/:teach_token', as: :deprecated_teach_course
  end

  # All admin routes
  namespace :admin do
    scope controller: :console do
      root action: :index

      get :'raise(/:type)', action: :test_raise, as: :raise
    end

    resource :test do
      collection do
        get :minimal_error
        get :minimal_error_iframe
        get :launch_iframe
        get :launch
      end
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
        post :roster
        post :set_ecosystem
        post :set_catalog_offering
        post :teachers, controller: :teachers
        delete :unpair_lms
      end

      post :bulk_update, on: :collection

      resources :periods, shallow: true, except: :index do
        member do
          put :restore
          put :change_salesforce
        end
      end
      resources :students, only: [:index] do
        member do
          delete :drop
          post :restore
        end
      end
      resources :teachers, only: [], shallow: true do
        member do
          delete :delete
          put :undelete
        end
      end
    end

    resources :students, only: :update do
      member do
        put :refund
      end
    end

    resources :schools, except: [:show]

    resources :districts, except: [:show]

    resources :notifications,  only: [:index, :create, :destroy]

    resources :targeted_contracts, except: [:show, :edit]

    resources :research_data, only: [:index, :create]

    resource :salesforce, only: [], controller: :salesforce do
      get :actions
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

    resources :payments, only: [:index] do
      collection do
        put :extend_payment_due_at
      end
    end
  end

  # All CS routes
  namespace :customer_service do
    root 'console#index'

    resources :users, only: [:index] do
      collection do
        get :info
      end
    end

    resources :ecosystems, only: [:index] do
      get :manifest, on: :member
    end

    resources :courses, only: [:index, :show] do
      resources :periods, only: [:index]
      resources :students, only: [:index]
    end

    resources :targeted_contracts, only: [:index]

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

    resources :ecosystems, only: [:index] do
      get :manifest, on: :member
    end

    resources :jobs, only: [:show]
  end

  # All research routes
  namespace :research do
    root 'console#index'

    get 'help', to: 'console#help'

    resources :studies do
      member do
        put :activate
        put :deactivate
      end

      resources :study_courses, shallow: true, only: [:create, :destroy]
      resources :brains, shallow: true
      resources :cohorts, shallow: true do
        put 'reassign_members'
        get 'members'
      end
    end

    resources :survey_plans, except: :destroy do
      member do
        get :preview
        put :publish
        delete :hide
        post :export
      end
    end
  end

  # Manage apps that use Tutor as an OAuth provider
  use_doorkeeper

  # Dev-only admin routes
  namespace :dev do
    resources :users, only: [:create] do
      post :generate, on: :collection
    end
  end

  scope '/lms', controller: :lms, as: :lms do
    get :configuration
    post :launch
    get :launch_authenticate
    get :complete_launch
    get :pair
    post :ci_launch
  end

  scope :specs do
    get 'lms_error_page/:page(/:case)' => 'lms_error_page_specs#page'
  end if Rails.env.test?

  # Catch-all frontend route
  match :'*other', to: 'webview#index', via: [:get, :post, :put, :patch, :delete]
end
