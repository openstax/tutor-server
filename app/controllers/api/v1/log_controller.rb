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
    entry_params = OpenStruct.new(entries: [])

    consume!(entry_params, represent_with: Api::V1::LogEntriesRepresenter)
    errors = []
    entries = entry_params.entries.empty? ? [entry_params] : entry_params.entries

    entries.each do |entry|

      if entry.level.blank?
        errors.push(:level_missing)
      else
        level = LOG_LEVELS[entry.level.try(:downcase)]
        errors.push(:bad_level) if level.nil?
      end

      errors.push(:message_missing) if entry.message.blank?

      render_api_errors(errors) && return

      message = entry.message[0..MAX_LOG_LENGTH]
      Rails.logger.log(level, "(ext) #{message}")
      head :created
    end
  end


  api :POST, '/log/onboarding/<event code>', 'Log that a user onboarding event has occured'
  def onboarding_event
    event_params = params.permit(:code, data: {})

    OSU::AccessPolicy.require_action_allowed!(
      event_params[:code], current_human_user, TrackTutorOnboardingEvent
    )

    TrackTutorOnboardingEvent.perform_later(event: event_params[:code],
                                            user: current_human_user,
                                            data: event_params[:data].to_h)
    head :created
  end
end
