require 'json-schema'

class DistributeTasks

  lev_routine

  uses_routine GetTaskeesFromTaskPlan, as: :get_taskees

  protected

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
    course_assistant = owner.is_a?(Course) ? \
                         assistant.course_assistants.where(course: owner) : nil
    data = course_assistant.try(:data) || {}
    taskees = run(:get_taskees, task_plan).outputs[:taskees]

    # Validate the given settings against the assistant's schema
    # Intervention settings already included when the task_plan was saved
    err = validate_json(assistant.schema, task_plan.settings)

    fatal_error(code: :invalid_settings,
                message: 'Invalid settings') unless err.empty?

    # Call the assistant code to create and distribute Tasks
    tasks = assistant.distribute_tasks(task_plan: task_plan, taskees: taskees)
  end

end
