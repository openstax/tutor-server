# Be sure to restart your server when you modify this file.
secrets = Rails.application.secrets['redis']

Settings.store = Redis::Store.new(
  url: secrets['url'],
  namespace: secrets['namespaces']['settings']
)
