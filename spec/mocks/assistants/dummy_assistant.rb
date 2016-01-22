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
      entity_task = Tasks::BuildTask[task_plan: @task_plan,
                                     title: @task_plan.title,
                                     description: @task_plan.description,
                                     task_type: :external].entity_task
      tasked = Tasks::Models::TaskedPlaceholder.new(placeholder_type: :exercise_type)
      step = Tasks::Models::TaskStep.new(tasked: tasked)
      entity_task.task.task_steps << step
      entity_task
    end
  end
end
