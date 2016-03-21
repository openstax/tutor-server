# The generic assistant is a base class for other assistants to inherit from
# It's not intended for direct use since it does not implement the all-important `build_tasks` method
class Tasks::Assistants::GenericAssistant
  attr_reader :task_plan, :taskees

  def initialize(task_plan:, taskees:)
    @task_plan = task_plan
    @taskees = taskees
  end

  def update_tasks_for_plan(tasking_plan:, where:, attributes:{})

    task_plan.tasks.update_all(title: task_plan.title, description: task_plan.description)

    task_plan.tasks.joins(:taskings)
      .where(where)
      .update_all(attributes.reverse_merge({
                   opens_at: tasking_plan.opens_at,
                   due_at: tasking_plan.due_at,
                   feedback_at: Time.now
                 }))

  end

end
