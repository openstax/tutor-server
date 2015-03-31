secrets = Rails.application.secrets['openstax']['exercises']

OpenStax::Exercises::V1.configure do |config|
  config.server_url  = secrets['url']
end

# Don't stub by default
secrets['stub'] ? OpenStax::Exercises::V1.use_fake_client : \
                  OpenStax::Exercises::V1.use_real_client
