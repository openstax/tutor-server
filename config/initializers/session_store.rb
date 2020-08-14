# Be sure to restart your server when you modify this file.

# MUST use secure: true, same_site: :none
# otherwise cookies will not be set inside iframes and break launching from lms in lms/launch_authenticate
if Rails.env.production?
  Rails.application.config.session_store :cookie_store, key: '_tutor_session', secure: true, same_site: :none
else
  Rails.application.config.session_store :cookie_store, key: '_tutor_session'
end
