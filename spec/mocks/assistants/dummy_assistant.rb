class DummyAssistant
  def self.schema
    "{}"
  end

  def self.create_tasks(task_plan:, taskees:)
    taskees.collect do |taskee|
      task = FactoryGirl.create :tasks_task, task_plan: task_plan
      FactoryGirl.create(:tasks_tasking, role: taskee, task: task.entity_task)
      task
    end
  end
end
