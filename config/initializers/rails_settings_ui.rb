require 'rails-settings-ui'

# Prevent deprecation warning:
# respond_to?(:respond_to_missing?) is old fashion which takes only one parameter
module RailsSettingsUi::MainAppRouteDelegator
  def respond_to?(method, include_private_methods = false)
    super || main_app_route_method?(method, include_private_methods)
  end

  private

  def main_app_route_method?(method, include_private_methods = false)
    method.to_s =~ /_(?:path|url)$/ && main_app.respond_to?(method, include_private_methods)
  end
end

#= Application-specific
#
# # You can specify a controller for RailsSettingsUi::ApplicationController to inherit from:
RailsSettingsUi.parent_controller = 'Admin::BaseController' # default: '::ApplicationController'
#
# # Render RailsSettingsUi inside a custom layout (set to 'application' to use app layout, default is RailsSettingsUi's own layout)

RailsSettingsUi.settings_class = "Settings::Db::Store"

Rails.application.config.to_prepare do
  # If you use a *custom layout*, make route helpers available to RailsSettingsUi:
  RailsSettingsUi.inline_main_app_routes!
  RailsSettingsUi::ApplicationController.module_eval do
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

        Settings::Db.store.object('excluded_ids').expire_cache
        new_excluded_ids = Settings::Exercises.excluded_ids
        SendGlobalExerciseExclusionsToBiglearn.perform_later if new_excluded_ids != old_excluded_ids
      end
    end
  end
end
