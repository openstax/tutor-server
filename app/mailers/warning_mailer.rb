require 'rails/backtrace_cleaner'

class WarningMailer < ApplicationMailer

  def warning(subject:, message:, details: {})
    @message = message
    @details = details
    mail subject: "[Tutor] (#{Rails.application.secrets.environment_name}) [Warning] #{subject}"
  end

  def self.log_and_deliver(args = {})
    args = { message: args } unless args.is_a?(Hash)

    if block_given?
      block_message = yield
      return unless block_message.present?
      block_message = { message: block_message } unless block_message.is_a?(Hash)
      args.merge!(block_message)
    end

    bc = Rails::BacktraceCleaner.new
    trace = bc.clean(caller)
    # regex extracts just the file and line portion
    trace.push(caller[0][/\/([\w|\.]+:\d+)/, 1]) if trace.empty?
    args[:subject] ||= trace[0]
    args[:details] ||= {}
    args[:details][:caller] = trace.join("\n")

    Rails.logger.warn(args[:message])
    self.warning(args).deliver_later
  end

end
