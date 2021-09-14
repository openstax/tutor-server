require 'omniauth/strategies/lti'

Rails.application.config.middleware.use OmniAuth::Strategies::Lti
