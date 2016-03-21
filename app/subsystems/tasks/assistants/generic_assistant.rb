# The generic assistant is a base class for other assistants to inherit from
# It's not intended for direct use since it does not implement the all-important `build_tasks` method
class Tasks::Assistants::GenericAssistant
  attr_reader :task_plan, :taskees

  def initialize(task_plan:, taskees:)
    @task_plan = task_plan
    @taskees = taskees
  end

end
