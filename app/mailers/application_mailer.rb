class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.secrets.exception['sender'],
          to: Rails.application.secrets.exception['recipients']

  layout 'mailer'
end
