# Be sure to restart your server when you modify this file.

class Settings::Db::Store < RailsSettings::CachedSettings
end

Settings::Db.store = Settings::Db::Store

Settings::Db.store.defaults[:excluded_uids] = ''
Settings::Db.store.defaults[:excluded_pool_uuid] = ''
Settings::Db.store.defaults[:import_real_salesforce_courses] = false
Settings::Db.store.defaults[:default_open_time] = '00:01'
Settings::Db.store.defaults[:default_due_time] = '07:00'
Settings::Db.store.defaults[:term_years_to_import] = ''

Settings::Db.store.defaults[:biglearn_client] =
  case Rails.env
  when "test"
    :fake
  when "development"
    :local_query_with_fake
  when "production"
    :local_query_with_real
  end

redis_secrets = Rails.application.secrets['redis']
Settings::Redis.store = Redis::Store.new(
  url: redis_secrets['url'],
  namespace: redis_secrets['namespaces']['settings']
)


