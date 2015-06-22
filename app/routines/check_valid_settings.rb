require 'json-schema'

class CheckValidSettings
  # Validate the given settings against the assistant's schema
  # Intervention settings already included when the task_plan was saved

  lev_routine express_output: :settings

  protected
  def exec(validatable:, options: {})
    options[:insert_defaults] = true if options[:insert_defaults].nil?

    if (err = JSON::Validator.fully_validate(validatable.assistant.schema,
                                             validatable.settings,
                                             options)).empty?
      outputs[:settings] = Hashie::Mash.new({ valid: true, errors: {} })
    else
      outputs[:settings] = Hashie::Mash.new({
        valid: false,
        errors: {
          code: :invalid_settings,
          message: 'Invalid settings',
          data: err
        }
      })
    end
  end
end
