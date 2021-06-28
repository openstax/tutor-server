content_secrets = Rails.application.secrets.openstax[:content]

OpenStax::Content.configure do |config|
  config.abl_url = content_secrets[:abl_url]
  config.archive_path = content_secrets[:archive_path]
  config.bucket_name = content_secrets[:bucket_name]
  config.domain = content_secrets[:domain]
  config.exercises_search_api_url = OpenStax::Exercises::V1.uri_for '/api/exercises'
  config.logger = Rails.logger
  config.s3_region = content_secrets[:s3_region]
  config.s3_access_key_id = content_secrets[:s3_access_key_id]
  config.s3_secret_access_key = content_secrets[:s3_secret_access_key]
end
