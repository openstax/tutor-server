class DummyAssistant
  def self.schema
    "{}"
  end

  def initialize(task_plan:, taskees:)
    @task_plan = task_plan
    @taskees = taskees
  end

  def build_tasks
    @taskees.collect do |taskee|
      Tasks::BuildTask[task_plan: @task_plan].entity_task
    end
  end
end
