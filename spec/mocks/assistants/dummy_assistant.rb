class DummyAssistant
  def self.schema
    "{}"
  end

  def self.build_tasks(task_plan:, taskees:)
    taskees.collect do |taskee|
      task = FactoryGirl.create(:tasks_task, task_plan: task_plan)
      entity_task = task.entity_task
      entity_task.taskings << FactoryGirl.create(:tasks_tasking, role: taskee, task: entity_task)
      task
    end
  end
end
