if Rails.env.production?
  ActionMailer::Base.add_delivery_method :ses, AWS::SES::Base,
    :access_key_id     => Rails.application.secrets.aws_ses_access_key_id,
    :secret_access_key => Rails.application.secrets.aws_ses_secret_access_key,
    :server => Rails.application.secrets.aws_ses_endpoint_server
end
