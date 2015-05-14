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
      task_plan.tasks.destroy_all
      task_plan.reload
    end

    owner = task_plan.owner
    assistant = task_plan.assistant
    taskees = run(:get_taskees, task_plan).outputs[:taskees]

    # Validate the given settings against the assistant's schema
    # Intervention settings already included when the task_plan was saved
    err = validate_json(assistant.schema, task_plan.settings)

    fatal_error(code: :invalid_settings, message: 'Invalid settings', data: err) \
      unless err.empty?

    # Call the assistant code to create and distribute Tasks
    outputs[:tasks] = assistant.distribute_tasks(task_plan: task_plan, taskees: taskees)
    task_plan.update_attributes(published_at: Time.now)
  end

end
