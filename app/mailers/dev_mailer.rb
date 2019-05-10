class DevMailer < ApplicationMailer

  def inspect_object(object:,
                     subject:,
                     to: Rails.application.secrets.exception[:recipients],
                     from: Rails.application.secrets.exception[:sender])
    @object = object

    mail_params = {
      subject: "[Tutor] (#{Rails.application.secrets.environment_name}) #{subject}",
      to: to,
      from: from
    }
    mail mail_params
  end

end
