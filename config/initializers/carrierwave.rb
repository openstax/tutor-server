require 'addressable/uri'

CarrierWave.configure do |config|
  # Image processing is non-deterministic so disable it in tests
  config.enable_processing = !Rails.env.test?

  # Upload to AWS only in the test and production environments
  # We default to file storage in the test environment but let specs opt into fog storage
  if Rails.env.development? || ActiveModel::Type::Boolean.new.cast(ENV.fetch('DISABLE_S3', false))
    config.storage = :file
  else
    config.fog_attributes = { 'Cache-Control' => 'max-age=31536000' }
    config.fog_provider = 'fog/aws'
    config.fog_public = false
    config.fog_authenticated_url_expiration = 1.hour

    s3_secrets = Rails.application.secrets.aws[:s3]

    config.asset_host = "https://#{s3_secrets[:exports_bucket_name]}.s3.amazonaws.com"
    config.fog_directory = s3_secrets[:exports_bucket_name]

    fog_credentials = s3_secrets[:access_key_id].blank? ?
      { use_iam_profile: true } :
      {
        aws_access_key_id:     s3_secrets[:access_key_id],
        aws_secret_access_key: s3_secrets[:secret_access_key]
      }
    config.fog_credentials = fog_credentials.merge(
      provider: 'AWS',
      region:   s3_secrets[:region]
    )

    # This line must be after config.fog_credentials=
    config.storage = Rails.env.production? ? :fog : :file
  end
end
