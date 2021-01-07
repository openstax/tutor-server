OpenStax::Utilities.configure do |config|
  config.status_authenticate = -> { raise SecurityTransgression unless current_user.is_admin? }
end
