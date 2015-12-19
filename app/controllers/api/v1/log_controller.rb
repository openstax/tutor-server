class Api::V1::LogController < Api::V1::ApiController

  LOG_LEVELS = {
    "unknown" => Logger::UNKNOWN,
    "fatal" => Logger::FATAL,
    "error" => Logger::ERROR,
    "warn" => Logger::WARN,
    "info" => Logger::INFO,
    "debug" => Logger::DEBUG
  }

  MAX_LOG_LENGTH = 1000

  resource_description do
    api_versions "v1"
    short_description 'Log entries'
    description <<-EOS
      TBD
    EOS
  end

  api :POST, '/log/entry', 'Submit a log message'
  description <<-EOS
    #{json_schema(Api::V1::LogEntryRepresenter, include: :writeable)}
  EOS
  def entry
    entry_params = OpenStruct.new
    consume!(entry_params, represent_with: Api::V1::LogEntryRepresenter)

    errors = []

    if entry_params.level.blank?
      errors.push(:level_missing)
    else
      level = LOG_LEVELS[entry_params.level.try(:downcase)]
      errors.push(:bad_level) if level.nil?
    end

    errors.push(:message_missing) if entry_params.message.blank?

    if errors.any?
      render_api_errors(errors)
    else
      message = entry_params.message[0..MAX_LOG_LENGTH]

      Rails.logger.log(level, message)
      head :created
    end
  end

end
