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
    around_action :create_biglearn_excluded_pool, only: :update_all

    protected

    def create_biglearn_excluded_pool
      old_excluded_uids = Settings::Exercises.excluded_uids

      yield

      new_excluded_uids = Settings::Exercises.excluded_uids
      return if new_excluded_uids == old_excluded_uids

      excluded_exercises = new_excluded_uids.split(',').map do |excluded_uid|
        excluded_number, excluded_version = excluded_uid.strip.split('@')
        OpenStax::Biglearn::V1::Exercise.new(question_id: excluded_number,
                                             version: excluded_version.to_i,
                                             tags: [])
      end

      excluded_pool = OpenStax::Biglearn::V1::Pool.new(exercises: excluded_exercises)
      excluded_pool = OpenStax::Biglearn::V1.add_pools([excluded_pool]).first
      Settings::Exercises.excluded_pool_uuid = excluded_pool.uuid
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
      field + (help_block_content.presence && content_tag(:span, help_block_content, class: 'help-block'))
    end
  end
end
