OpenStax::Utilities.configure do |config|
  config.status_authenticate = -> do
    authenticate_user!

    next if performed? || current_user.is_admin?

    raise SecurityTransgression
  end
end
