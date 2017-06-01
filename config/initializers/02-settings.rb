# Be sure to restart your server when you modify this file.

class Settings::Db::Store < RailsSettings::CachedSettings
end

Settings::Db.store = Settings::Db::Store

Settings::Db.store.defaults[:excluded_ids] = ''
Settings::Db.store.defaults[:import_real_salesforce_courses] = false
Settings::Db.store.defaults[:default_open_time] = '00:01'
Settings::Db.store.defaults[:default_due_time] = '07:00'
Settings::Db.store.defaults[:term_years_to_import] = ''
Settings::Db.store.defaults[:student_grace_period_days] = 14
Settings::Db.store.defaults[:payments_enabled] = false

secrets = Rails.application.secrets

biglearn_secrets = secrets['openstax']['biglearn']
biglearn_stub = biglearn_secrets['stub'].nil? ? true : biglearn_secrets['stub']
Settings::Db.store.defaults[:biglearn_client] = biglearn_stub ? :fake : :real
Settings::Db.store.defaults[:biglearn_student_clues_algorithm_name] = 'local_query'
Settings::Db.store.defaults[:biglearn_teacher_clues_algorithm_name] = 'local_query'
Settings::Db.store.defaults[:biglearn_assignment_spes_algorithm_name] = 'student_driven_local_query'
Settings::Db.store.defaults[:biglearn_assignment_pes_algorithm_name] = 'local_query'
Settings::Db.store.defaults[:biglearn_practice_worst_areas_algorithm_name] = 'local_query'

redis_secrets = secrets['redis']
Settings::Redis.store = Redis::Store.new(
  url: redis_secrets['url'],
  namespace: redis_secrets['namespaces']['settings']
)

Settings::Db.store.defaults[:prebuilt_preview_course_count] = 10

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

Settings::Db.store.defaults[:pardot_toa_redirect] = ""
