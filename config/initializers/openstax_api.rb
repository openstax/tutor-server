OpenStax::Api.configure do |config|
  config.user_class_name = 'UserProfile::Models::Profile'
  config.current_user_method = 'current_user'
  config.routing_error_app = lambda { |env|
    [404, {"Content-Type" => 'application/json'}, ['']] }
end
