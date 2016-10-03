require 'rails-settings-ui'

#= Application-specific
#
# # You can specify a controller for RailsSettingsUi::ApplicationController to inherit from:
RailsSettingsUi.parent_controller = 'Admin::BaseController' # default: '::ApplicationController'
#
# # Render RailsSettingsUi inside a custom layout (set to 'application' to use app layout, default is RailsSettingsUi's own layout)
# RailsSettingsUi::ApplicationController.layout 'admin'

RailsSettingsUi.settings_class = "Settings::Db::Store"

RailsSettingsUi.settings_displayed_as_select_tag = [:biglearn_client]

Rails.application.config.to_prepare do
  # If you use a *custom layout*, make route helpers available to RailsSettingsUi:
  RailsSettingsUi.inline_main_app_routes!

  # Automatically create the admin Biglearn exclusion pool when settings are saved
  RailsSettingsUi::ApplicationController.class_exec do
    around_action :send_exercise_exclusions_to_biglearn, only: :update_all

    protected

    def send_exercise_exclusions_to_biglearn
      ActiveRecord::Base.transaction do
        old_excluded_ids = Settings::Exercises.excluded_ids

        yield

        new_excluded_ids = Settings::Exercises.excluded_ids
        return if new_excluded_ids == old_excluded_ids

        OpenStax::Biglearn::Api.update_global_exercise_exclusions(exercise_ids: new_excluded_ids)
      end
    end
  end

  # Change the length limit on settings so that UUID's render as a text input (not textarea)
  RailsSettingsUi::SettingsHelper.module_exec do
    def text_field(setting_name, setting_value, options = {})
      field = if setting_value.to_s.size > 36
        text_area_tag("settings[#{setting_name}]", setting_value.to_s, options.merge(rows: 10))
      else
        text_field_tag("settings[#{setting_name}]", setting_value.to_s, options)
      end

      help_block_content = I18n.t("settings.attributes.#{setting_name}.help_block", default: '')
      field + (help_block_content.presence &&
               content_tag(:span, help_block_content, class: 'help-block'))
    end
  end
end
