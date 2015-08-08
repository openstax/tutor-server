class DummyAssistant
  def self.schema
    "{}"
  end

  def initialize(task_plan:, taskees:)
    @task_plan = task_plan
    @taskees = taskees
  end

  def self.build_tasks
    @taskees.collect do |taskee|
      task = FactoryGirl.create(:tasks_task, task_plan: @task_plan)
      entity_task = task.entity_task
      entity_task.taskings << FactoryGirl.create(:tasks_tasking, role: taskee, task: entity_task)
      task
    end
  end
end
