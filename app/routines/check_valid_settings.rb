require 'json-schema'

class CheckValidSettings
  # Validate the given settings against the assistant's schema
  # Intervention settings already included when the task_plan was saved

  lev_routine express_output: :settings,
              raise_fatal_errors: false

  protected
  def exec(validatable:, options: {})
    options[:insert_defaults] = true if options[:insert_defaults].nil?

    if (err = JSON::Validator.fully_validate(validatable.assistant.schema,
                                             validatable.settings,
                                             options)).empty?
      outputs[:settings] = { valid: true, errors: [] }
    else
      nonfatal_error(code: :invalid_settings, message: 'Invalid settings', data: err)

      outputs[:settings] = {
        valid: false,
        errors: errors
      }
    end
  end
end
