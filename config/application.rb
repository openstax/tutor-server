require_relative 'boot'

# https://github.com/rails/rails/blob/master/railties/lib/rails/all.rb
# Minus ActiveStorage, ActionCable and Rails 6 stuff (ActionMailbox and ActionText)
require 'rails'

%w(
  active_record/railtie
  action_controller/railtie
  action_view/railtie
  action_mailer/railtie
  active_job/railtie
  rails/test_unit/railtie
  sprockets/railtie
).each do |railtie|
  begin
    require railtie
  rescue LoadError
  end
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

# For cache entries that should never expire but that we still want to evict if Redis is OOM
NEVER_EXPIRES = 68.years

module Tutor
  class Application < Rails::Application
    # Initialize configuration defaults for current Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # add app/assets/fonts and app/assets/html to the asset path
    config.assets.paths << Rails.root.join("app", "assets", "fonts")
    config.assets.paths << Rails.root.join("app", "assets", "html")

    # add concern folders to the autoload path
    config.eager_load_paths << Rails.root.join('app', 'routines', 'concerns')

    # Use Redis as the cache store
    # This setting cannot be set from an initializer
    # See https://github.com/rails/rails/issues/10908
    redis_secrets = secrets.redis
    config.cache_store = :redis_store, {
      url: redis_secrets[:url],
      namespace: redis_secrets[:namespaces][:cache],
      expires_in: 90.minutes
    }

    # Use a real queuing backend for Active Job (and separate queues per environment)
    config.active_job.queue_adapter = :delayed_job
    config.active_job.queue_name_prefix = "tutor_#{Rails.env}"

    # Skip helper, asset and view spec generation when generating scaffolds
    config.generators do |g|
      g.helper false
      g.assets false
      g.view_specs false
    end

    # rack-attack for throttling
    Rack::Attack.cache.store = ActiveSupport::Cache::RedisStore.new(
      url: redis_secrets[:url],
      expires_in: 2.days
    )

    config.middleware.use Rack::Attack

    config.after_initialize do
      require 'rack-attack-settings'
    end
  end
end
