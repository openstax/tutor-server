if Rails.env.production?
  ses_secrets = Rails.application.secrets.aws[:ses]

  ActionMailer::Base.add_delivery_method(
    :ses,
    AWS::SES::Base,
    access_key_id:     ses_secrets[:access_key_id],
    secret_access_key: ses_secrets[:secret_access_key],
    server:            ses_secrets[:endpoint_server]
  )
end
