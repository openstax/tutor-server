# Be sure to restart your server when you modify this file.

class Settings::Db::Store < RailsSettings::CachedSettings
end
Settings::Db.store = Settings::Db::Store
Settings::Db.store.defaults[:excluded_uids] = ''
Settings::Db.store.defaults[:excluded_pool_uuid] = ''
Settings::Db.store.defaults[:import_real_salesforce_courses] = false
Settings::Db.store.defaults[:course_default_open_time] = '00:00'
Settings::Db.store.defaults[:course_default_due_time] = '00:00'
Settings::Db.store.defaults[:period_default_open_time] = '00:00'
Settings::Db.store.defaults[:period_default_due_time] = '00:00'

redis_secrets = Rails.application.secrets['redis']
Settings::Redis.store = Redis::Store.new(
  url: redis_secrets['url'],
  namespace: redis_secrets['namespaces']['settings']
)
