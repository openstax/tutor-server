require 'rails-settings-ui'

# Compatibility with newer versions of rails-settings-cached
module RailsSettingsUi
  class << self
    def default_settings
      settings = RailsSettingsUi.settings_klass.get_all
      settings.reject { |name, _description| ignored_settings.include?(name.to_sym) }
    end
  end
end

RailsSettingsUi.setup do |config|
  # Specify a controller for RailsSettingsUi::ApplicationController to inherit from:
  config.parent_controller = 'Admin::BaseController' # default: '::ApplicationController'

  config.settings_class = 'Settings::Db'

  config.settings_displayed_as_select_tag = [
    :biglearn_student_clues_algorithm_name,
    :biglearn_teacher_clues_algorithm_name,
    :biglearn_assignment_spes_algorithm_name,
    :biglearn_assignment_pes_algorithm_name,
    :biglearn_practice_worst_areas_algorithm_name
  ]
end

Rails.application.config.to_prepare do
  # If you use a *custom layout*, make route helpers available to RailsSettingsUi:
  RailsSettingsUi.inline_engine_routes!
  RailsSettingsUi::ApplicationController.module_eval do
    # Render RailsSettingsUi inside a custom layout
    # (set to 'application' to use app layout, default is RailsSettingsUi's own layout)
    layout 'admin'
  end

  # Automatically create the admin Biglearn exclusion pool when settings are saved
  RailsSettingsUi::ApplicationController.class_exec do
    around_action :send_exercise_exclusions_to_biglearn, only: :update_all

    protected

    def send_exercise_exclusions_to_biglearn
      ActiveRecord::Base.transaction do
        old_excluded_ids = Settings::Exercises.excluded_ids

        yield

        Settings::Db.clear_cache
        new_excluded_ids = Settings::Exercises.excluded_ids
        SendGlobalExerciseExclusionsToBiglearn.perform_later if new_excluded_ids != old_excluded_ids
      end
    end
  end
end
