# Be sure to restart your server when you modify this file.
secrets = Rails.application.secrets['redis']

Rails.application.config.cache_store = :redis_store, {
  url: secrets['url'],
  namespace: secrets['namespaces']['cache'],
  expires_in: 90.minutes
}
