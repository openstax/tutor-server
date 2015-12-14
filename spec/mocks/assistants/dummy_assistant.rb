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
      Tasks::BuildTask.call(task_plan: @task_plan,
                            title: @task_plan.title,
                            description: @task_plan.description,
                            task_type: :external).entity_task
    end
  end
end
