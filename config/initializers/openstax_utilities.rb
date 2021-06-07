OpenStax::Utilities.configure do |config|
  config.status_authenticate = -> do
    authenticate_user!

    next if performed? || request.host != 'tutor.openstax.org' || current_user.is_admin?

    raise SecurityTransgression
  end
end
