class DevMailer < ApplicationMailer

  def inspect_object(object:, to: nil, from: nil, subject:)
    @object = object
    mail to: to || Rails.application.secrets.exception['recipients'],
         from: from || Rails.application.secrets.exception['sender'],
         subject: subject
  end

end
