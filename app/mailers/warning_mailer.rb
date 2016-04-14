require 'rails/backtrace_cleaner'

class WarningMailer < ApplicationMailer

  default(
    to: Rails.application.secrets.exception['recipients'],
    from: Rails.application.secrets.exception['sender']
  )

  def warning(subject:, message:, details: {})
    @message = message
    if 1 == details
      debugger
    end
    @details = details

    mail(subject: "[warning] #{subject}")
  end

  def self.log_and_deliver
    warning = yield
    return unless warning

    unless warning.is_a?(Hash)
      warning = {
        message: warning
      }
    end
    bc = Rails::BacktraceCleaner.new
    trace = bc.clean(caller)
    # regex extracts just the file and line portion
    trace.push(caller[0][/\/([\w|\.]+:\d+)/, 1]) if trace.empty?
    warning[:subject] ||= trace[0]
    warning[:details] ||= {}
    warning[:details][:caller] = trace.join("\n")

    Rails.logger.warn(warning[:message])
    self.warning(warning).deliver_later
  end

end
