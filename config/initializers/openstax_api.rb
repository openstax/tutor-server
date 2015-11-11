OpenStax::Api.configure do |config|
  config.user_class_name = 'User::User'
  config.current_user_method = 'current_user'
  config.routing_error_app = lambda { |env|
    [404, {"Content-Type" => 'application/json'}, ['']] }
  config.validate_cors_origin = lambda{ |request|
    (Rails.application.secrets.cc_origins || []).any? do | origin |
      /^#{origin}/.match(request.headers["HTTP_ORIGIN"])
    end
  }
end

# Override the human_user method so it can properly return a User::User
OpenStax::Api::ApiUser.class_exec do
  def human_user
    return @user if @user.present?

    if @doorkeeper_token.present?
      ::User::User.find(@doorkeeper_token.resource_owner_id) rescue @non_doorkeeper_user_proc.call
    else
      @non_doorkeeper_user_proc.call
    end
  end
end
