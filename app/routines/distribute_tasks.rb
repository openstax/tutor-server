require 'json-schema'

class DistributeTasks

  lev_routine

  uses_routine GetTaskeesFromTaskPlan, as: :get_taskees

  protected

  def get_settings(obj, assistant)
    case obj
    when Klass
      obj.klass_assistants.active.where(assistant: assistant).pluck(:settings)
    when Study
      obj.study_assistants.active.where(assistant: assistant).pluck(:settings)
    else
      {}
    end
  end

  def validate_json(schema, object, options = {})
    options[:insert_defaults] = true if options[:insert_defaults].nil?

    JSON::Validator.fully_validate(schema, object, options)
  end

  def exec(task_plan)
    # Delete pre-existing assignments
    unless task_plan.tasks.empty?
      task_plan.tasks.delete_all # Delete using the foreign key cascade
      task_plan.reload
    end

    owner = task_plan.owner
    assistant = task_plan.assistant
    taskees = run(:get_taskees, task_plan).outputs[:taskees]

    # Get owner (Course) and study settings
    owner_settings = get_settings(owner)

    # Tasker (Teacher) settings
    tasker_settings = task_plan.settings

    # Get Study settings
    study_settings = owner.is_a?(Klass) ? get_settings(owner.study) : {}

    # Tasker settings override owner settings
    # Study settings override all others
    # UI disables overriden controls
    settings = owner_settings.merge(tasker_settings).merge(study_settings)

    # Validate the given settings against the schema
    err = validate_json(schema, settings)

    fatal_error(code: :invalid_settings,
                message: 'Invalid settings') unless err.empty?

    # Call the appropriate assistant code
    assistant.task_taskees(task_plan, taskees, settings)
  end

end
