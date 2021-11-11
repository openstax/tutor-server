Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  # Try to list more often used routes first, although catch-all routes have to be at the end

  # Home page, course picker, course dashboard and student enrollment
  scope controller: :webview do
    root action: :home

    scope :enroll do
      # this is handled by the FE
      get :'start/:enroll_token', action: :index,
                                  as: :start_enrollment,
                                  block_sign_up: false,
                                  straight_to_student_sign_up: true
      # we render this to display a splash screen before login/signup
      get :':enroll_token(/*ignored)', as: :token_enroll, action: :enroll
    end

    # The routes below would be served by the webview catch-all route,
    # but we define them so we can use them as helpers that point to certain FE pages
    scope action: :index do
      # routes that are handled by the FE
      get :courses, as: :dashboard
      get :'course/:id', as: :course_dashboard
      get :'course/:course_id/task/:task_id', as: :student_task
      get :'course/:course_id/assignment/review/:task_id', as: :teacher_task_plan_review
    end
  end

  mount OpenStax::Accounts::Engine => :accounts

  post 'auth/lti/callback', to: 'lti#callback' # LTI authentication success
  namespace :lti do
    get  :launch # LTI launch after Accounts login (after authentication)
    post :pair   # Pair courses with LMS
  end

  get :non_student_signup, to: redirect('/courses?block_sign_up=false&straight_to_sign_up=true')

  # Short codes
  get :'@/:short_code(/:human_readable)', to: 'short_codes#redirect', as: :short_code

  # All API routes
  api :v1, default: true do

    resources :users, only: :index
    resource :user, only: :show do
      get :bootstrap
      get :tasks
      put :ui_settings
      put :'tours/:tour_id', action: :record_tour_view
      post :suggest

      resources :courses, only: :index do
        put :'student(/role/:role_id)', controller: :students, action: :update_self
      end
    end

    resources :updates, only: :index

    namespace :log do
      post :entry
      post :'event/onboarding/:code', action: :onboarding_event
    end

    resources :purchases, only: :index do
      member do
        put :check
        put :refund
      end

      post(:fake, action: :create_fake, on: :collection) unless IAm.real_production?
    end

    put '/payment_codes/:code/redeem', to: 'payment_codes#redeem', as: :payment_code_redeem

    resources :tasks, only: [ :show, :destroy ] do
      resources :steps, controller: :task_steps, shallow: true, only: [ :show, :update ] do
        put :grade, on: :member
      end
    end

    resources :research_surveys, only: :update

    resources :courses, only: [ :create, :show, :update ] do
      member do
        get :'dashboard(/role/:role_id)', action: :dashboard
        get :roster
        get :teachers
        post :clone
      end

      scope controller: :performance_reports do
        get :'performance(/role/:role_id)', action: :index
        post :'performance/export(/role/:role_id)', action: :export
        get :'performance/exports(/role/:role_id)', action: :exports
      end

      resource :practices, path: :'practice/(/role/:role_id)', only: [ :create ]
      post :'practice/worst(/role/:role_id)', controller: :practices, action: :create_worst
      post :'practice/saved(/role/:role_id)', controller: :practices, action: :create_saved
      put :'practice/:id/exit(/role/:role_id)', controller: :practices, action: :exit
      get :'practice/saved(/role/:role_id)', controller: :practices, action: :find_saved

      resources :practice_questions, only: [ :index, :create, :destroy ]

      scope controller: :guides do
        get :'guide(/role/:role_id)', action: :student
        get :'teacher_guide(/role/:role_id)', action: :teacher
      end

      post :dates, on: :collection

      resources :exercises, controller: :course_exercises, only: [ :create, :destroy ] do
        collection do
          get :'(/:pool_types)', action: :index
          put :exclude
        end
      end

      resources :grading_templates, shallow: true, only: [ :index, :create, :update, :destroy ]

      resources :task_plans, path: :plans, shallow: true, except: [ :new, :edit ] do
        member do
          get :stats
          get :review
          get :scores
          put :restore
        end

        resources :tasking_plans, shallow: true, only: [] do
          put :grade, on: :member
        end
      end

      resources :students, shallow: true, except: [ :index, :create ] do
        put :restore, on: :member
        # For backwards-compatibility: remove when the FE stops using it
        put :undrop, on: :member, action: :restore
      end

      resources :teachers, shallow: true, only: :destroy

      resources :periods, shallow: true, only: [ :create, :update, :destroy ] do
        member do
          put :restore
          put :teacher_student
        end
      end
    end

    resources :pages, only: [] do
      resources :notes, shallow: true, only: [ :index, :create, :update, :destroy ]
    end
    get :'books/:book_uuid/highlighted_sections', controller: :notes, action: :highlighted_sections

    resources :ecosystems, only: :index do
      member do
        get :readings
        get :'exercises(/:pool_types)', action: :exercises
        get :'practice_exercises', action: :practice_exercises
      end

      get :'pages/*ox_id', controller: :pages, action: :show, format: false
    end

    resources :enrollment, only: :create do
      post :prevalidate, on: :collection

      member do
        put :approve
        get :choices
      end
    end

    resources :offerings, only: :index

    resources :jobs, only: [ :index, :show ]

    resources :terms, only: :index do
      put :':ids', on: :collection, action: :sign
    end

    namespace :lms do
      resources :courses, only: :show do
        member do
          put :push_scores
          post :pair
        end
      end
    end

    namespace :demo do
      post :all
      post :users
      post :import
      post :course
      post :assign
      post :work
    end unless IAm.real_production?

    namespace :research do
      post :/, action: :research, controller: :root

      namespace :sparfa do
        post :students
        post :task_plans
      end
    end

    match :'*all', controller: :api, action: :options, via: :options
  end # end of API scope

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
    get :'auth/failure', action: :omniauth_failure
    get :signup
    get :stubbed_payments
    get :browser_upgrade
  end

  scope :lms, controller: :lms, as: :lms do
    get :configuration
    post :launch
    get :'launch_authenticate/:launch_uuid', action: :launch_authenticate, as: :launch_authenticate
    get :complete_launch
    get :pair
    post :ci_launch
  end

  get(:'specs/lms_error_page/:page(/:case)', controller: :lms_error_page_specs, action: :page) \
    if Rails.env.test?

  # Teacher enrollment
  get :'teach/:teach_token(/:ignore)', controller: :courses, action: :teach, as: :teach_course

  # All admin routes
  namespace :admin do
    scope controller: :console do
      root action: :index

      get :'raise(/:type)', action: :test_raise, as: :raise
    end

    mount RailsSettingsUi::Engine => :settings

    mount OpenStax::Salesforce::Engine => :openstax_salesforce

    resource :test do
      collection do
        get :minimal_error
        get :minimal_error_iframe
        get :launch_iframe
        get :launch
      end
    end

    resources :users, except: :destroy do
      post :become, on: :member

      get :info, on: :collection
    end

    resources :administrators, only: [ :index, :create, :destroy ]

    resources :ecosystems, except: :edit do
      get :manifest, on: :member
    end

    resources :catalog_offerings, except: :show do
      put :restore, on: :member
    end

    resources :courses, except: :show do
      member do
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

      resources :students, only: [ :index, :update, :destroy ], shallow: true do
        member do
          put :refund
          put :restore
        end
      end

      resources :teachers, only: :destroy, shallow: true do
        put :restore, on: :member
      end
    end

    resources :schools, except: :show

    resources :districts, except: :show

    resources :notifications, only: [ :index, :create, :destroy ]

    resources :targeted_contracts, except: [ :show, :edit, :update ]

    resources :research_data, only: [ :index, :create ]

    resource :salesforce, controller: :salesforce, only: [] do
      get :failures
    end

    resource :cron, only: :update

    resources :exceptions, only: :show

    resources :jobs, only: [ :index, :show ]

    resources :tags, only: [ :index, :edit, :update, :show ]

    resources :payments, only: :index do
      collection do
        put :extend_payment_due_at
        post :generate_payment_codes
        get :download_payment_code_report
      end
    end

    namespace :demo do
      get :users
      get :import
      get :course
      get :assign
      get :work
      get :all
    end unless IAm.real_production?

  end # end of admin namespace

  # All CS routes
  namespace :customer_service do
    root controller: :console, action: :index

    resources :users, only: :index do
      collection do
        get :info
      end
    end

    resources :ecosystems, only: :index do
      get :manifest, on: :member
    end

    resources :courses, only: [ :index, :show ] do
      resources :periods, only: :index
      resources :students, only: :index
    end

    resources :targeted_contracts, only: :index

    resources :jobs, only: [ :index, :show ]

    resources :tags, only: [ :index, :show ]
  end

  # All CM routes
  namespace :content_analyst do
    root controller: :console, action: :index

    resources :ecosystems, only: :index do
      get :manifest, on: :member
    end

    resources :jobs, only: :show
  end

  # All non-API research routes
  namespace :research do
    scope controller: :console do
      root action: :index

      get :help
    end

    resources :studies do
      member do
        put :activate
        put :deactivate
      end

      resources :study_courses, shallow: true, only: [ :create, :destroy ]
      resources :cohorts, shallow: true do
        put :reassign_members
        get :members
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

  get :'pardot/toa', controller: :pardot, action: :toa

  resources :purchases, only: :show

  # Terms of use/Privacy policy
  resources :terms, only: :index do
    collection do
      get :pose
      post :agree, as: :agree_to
    end
  end

  mount FinePrint::Engine => :fine_print
  mount ActiveStorage::Engine, at: '/rails/active_storage'
  mount OpenStax::Utilities::Engine => :status

  # API docs
  apipie

  # Manage apps that use Tutor as an OAuth provider
  use_doorkeeper

  # Dev-only admin routes
  namespace :dev do
    resources :users, only: :create do
      post :generate, on: :collection
    end
  end

  # Local dev redirect to static error pages (these are served as static files in real servers)
  [ 404, 422, 500, 503 ].each { |code| get code.to_s, to: redirect("/assets/#{code}.html") }

  # Return a 404 error for missing assets
  get :'assets/*other', to: ->(env) { [404, {}, ['']] }

  # Catch-all frontend route, excluding active_storage
  # the constraint shouldn't be needed once upgrade to rails 6
  get :'*other', controller: :webview, action: :index, constraints: ->(req) do
    req.path.exclude? 'rails/active_storage'
  end
end
