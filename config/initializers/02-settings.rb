# Be sure to restart your server when you modify this file.

class Settings::Db::Store < RailsSettings::CachedSettings
end

Settings::Db.store = Settings::Db::Store

Settings::Db.store.defaults[:excluded_ids] = ''
Settings::Db.store.defaults[:import_real_salesforce_courses] = false
Settings::Db.store.defaults[:default_open_time] = '00:01'
Settings::Db.store.defaults[:default_due_time] = '07:00'
Settings::Db.store.defaults[:term_years_to_import] = ''

secrets = Rails.application.secrets

biglearn_secrets = secrets['openstax']['biglearn']
biglearn_stub = biglearn_secrets.fetch('stub', true)
Settings::Db.store.defaults[:biglearn_client] = biglearn_stub ? :fake : :real
Settings::Db.store.defaults[:biglearn_algorithm_name] = biglearn_stub ? :local_query : :sparfa

redis_secrets = secrets['redis']
Settings::Redis.store = Redis::Store.new(
  url: redis_secrets['url'],
  namespace: redis_secrets['namespaces']['settings']
)

Settings::Db.store.defaults[:course_appearance_codes] = {
    hs_physics:           'Physics',
    ap_biology:           'AP Biology',
    principles_economics: 'Principles of Economics',
    macro_economics:      'Macro Economics',
    college_physics:      'College Physics',
    micro_economics:      'Micro Economics',
    concepts_biology:     'Concepts of Biology',
    college_biology:      'College Biology',
    intro_sociology:      'Intro to Sociology',
    anatomy_physiology:   'Anatomy and Physiology'
}
