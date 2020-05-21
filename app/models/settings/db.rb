# RailsSettings Model
module Settings
  class Db < RailsSettings::Base
    # rails-settings-ui needs a list of all settings
    @fields = []

    class << self
      def [](key)
        public_send key
      end

      def []=(key, value)
        public_send "#{key}=", value
      end

      def get_all
        HashWithIndifferentAccess.new.tap do |result|
          @fields.sort.each { |field| result[field] = public_send(field) }
        end
      end

      private

      def _define_field(key, *rest)
        super

        @fields << key
      end
    end

    cache_prefix { "v1" }

    # Define your fields
    # field :host, type: :string, default: "http://localhost:3000"
    field :excluded_ids, type: :string, default: ''
    field :import_real_salesforce_courses, type: :boolean, default: false
    field :default_open_time, type: :string, default: '00:01'
    field :default_due_time, type: :string, default: '07:00'
    field :term_years_to_import, type: :string, default: ''
    field :pulse_insights, type: :boolean, default: false
    field :force_browser_reload, type: :boolean, default: false
    field :student_grace_period_days, type: :integer, default: 14
    field :ga_tracking_codes, type: :string, default: \
        (Rails.application.secrets.environment_name == "prodtutor") ? 'UA-66552106-1' : ''
    field :active_onboarding_salesforce_campaign_id, type: :string, default: ''
    field :active_nomad_onboarding_salesforce_campaign_id, type: :string, default: ''
    field :find_tutor_course_period_report_id, type: :string, default: ''

    field :biglearn_student_clues_algorithm_name, type: :symbol, default: :biglearn_sparfa
    field :biglearn_teacher_clues_algorithm_name, type: :symbol, default: :biglearn_sparfa
    field :biglearn_assignment_spes_algorithm_name, type: :symbol, default: \
      :student_driven_biglearn_sparfa
    field :biglearn_assignment_pes_algorithm_name, type: :symbol, default: :biglearn_sparfa
    field :biglearn_practice_worst_areas_algorithm_name, type: :symbol, default: :biglearn_sparfa

    field :default_is_lms_enabling_allowed, type: :boolean, default: true

    field :prebuilt_preview_course_count, type: :integer, default: 10

    field :course_appearance_codes, type: :hash, default: {
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

    field :pardot_toa_redirect, type: :string, default: ''

    field :raise_if_salesforce_user_missing, type: :boolean, default: !Rails.env.development?

    # feature flag defaults
    field :payments_enabled, type: :boolean, default: false
    field :response_validation_enabled, type: :boolean, default: true
    field :response_validation_ui_enabled, type: :boolean, default: true
    field :teacher_student_enabled, type: :boolean, default: true
  end
end
