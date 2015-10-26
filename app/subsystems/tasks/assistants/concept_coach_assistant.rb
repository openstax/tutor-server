class Tasks::Assistants::ConceptCoachAssistant

  def self.schema
    '{}'
  end

  def initialize(task_plan:, taskees:)
    @task_plan = task_plan
    @taskees = taskees
  end

  def build_tasks
    raise NotImplementedError
  end

  protected

  def logger
    Rails.logger
  end

end
