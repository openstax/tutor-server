VALID_IFRAME_ORIGINS = Rails.application.secrets.cc_origins ?
  Rails.application.secrets.cc_origins.map{ |origin| Regexp.new("\\A#{origin}") } : []


OpenStax::Api.configure do |config|
  config.user_class_name = 'User::Models::Profile'
  config.current_user_method = 'current_user'
  config.routing_error_app = ->(env) { [404, {"Content-Type" => 'application/json'}, ['']] }

  if VALID_IFRAME_ORIGINS.any?
    config.validate_cors_origin = lambda do |request|
      VALID_IFRAME_ORIGINS.any?{ | origin | origin.match(request.headers["HTTP_ORIGIN"]) }
    end
  end
end

ActiveSupport::Reloader.to_prepare do
  # Override the human_user method so it can properly return a User::Models::Profile
  OpenStax::Api::ApiUser.class_exec do
    def human_user
      return @user if @user.present?

      if @doorkeeper_token.present?
        ::User::Models::Profile.find(@doorkeeper_token.resource_owner_id) rescue @non_doorkeeper_user_proc.call
      else
        @non_doorkeeper_user_proc.call
      end
    end
  end
end
