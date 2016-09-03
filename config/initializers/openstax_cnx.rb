secrets = Rails.application.secrets['openstax']['cnx']

OpenStax::Cnx::V1.configure do |config|
  config.archive_url_base = secrets['archive_url']
end
