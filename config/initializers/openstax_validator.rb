secrets = Rails.application.secrets.response_validation

OpenStax::Validator::V1.configure do |config|
  config.server_url = secrets[:url]
  config.timeout    = secrets[:timeout]
  config.stub       = ActiveAttr::Typecasting::BooleanTypecaster.new.call(secrets[:stub])
end
