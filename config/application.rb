require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Tutor
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # add app/assets/fonts to the asset path
    config.assets.paths << Rails.root.join("app", "assets", "fonts")

    # For not swallowing errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # Temporary fix until we update openstax_api
    # to include this for JSON responses
    ActiveSupport.escape_html_entities_in_json = false

    # Set the default cache store to Redis
    # This setting cannot be set from an initializer
    # See https://github.com/rails/rails/issues/10908
    redis_secrets = secrets['redis']
    config.cache_store = :redis_store, {
      url: redis_secrets['url'],
      namespace: redis_secrets['namespaces']['cache'],
      expires_in: 90.minutes
    }

    # Use delayed_job for background jobs
    config.active_job.queue_adapter = :delayed_job

    config.generators do |g|
      g.skip_routes true
      g.helper false
      g.assets false
      g.view_specs false
    end
  end
end
