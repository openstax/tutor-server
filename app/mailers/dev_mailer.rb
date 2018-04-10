class DevMailer < ApplicationMailer

  def inspect_object(object:, from: nil, to: nil, subject:)
    @object = object
    mail_params = { subject: "[Tutor] (#{Rails.application.secrets.environment_name}) #{subject}" }
    mail_params[:from] = from unless from.nil?
    mail_params[:to] = to unless to.nil?

    mail mail_params
  end

end
