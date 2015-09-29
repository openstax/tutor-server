Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = true

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = EnvUtilities.load_boolean(name: 'USE_DEV_ERROR_RESPONSES',
                                                                       default: true)
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Asset digests allow you to set far-future HTTP expiration dates on all assets,
  # yet still be able to expire them through the digest params.
  config.assets.digest = true

  # Adds additional error checking when serving assets at runtime.
  # Checks for improperly declared sprockets dependencies.
  # Raises helpful error messages.
  config.assets.raise_runtime_errors = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Don't error out when trying to connect to external sites
  WebMock.allow_net_connect!

  # Only enable Bullet on request since it does add overhead
  if EnvUtilities.load_boolean(name: 'ENABLE_BULLET', default: false)
    config.after_initialize do
      Bullet.enable = true
      Bullet.bullet_logger = true # tail -f log/bullet.log
    end
  end

  # Use fake "background" jobs by default
  # (real background jobs require redis and cache_classes = true or some entity autoload fix)
  use_real_background_jobs = EnvUtilities.load_boolean(name: 'USE_REAL_BACKGROUND_JOBS',
                                                       default: false)
  config.active_job.queue_adapter = use_real_background_jobs ? :resque : :inline
end
