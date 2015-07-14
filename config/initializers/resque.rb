# Be sure to restart your server when you modify this file.
secrets = Rails.application.secrets['redis']

Resque.redis = Addressable::URI.join(secrets['url'], secrets['namespaces']['resque'])
