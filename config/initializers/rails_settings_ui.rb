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

ActiveSupport::Reloader.to_prepare do
  # If you use a *custom layout*, make route helpers available to RailsSettingsUi:
  RailsSettingsUi.inline_engine_routes!

  RailsSettingsUi::ApplicationController.layout 'admin'
end
