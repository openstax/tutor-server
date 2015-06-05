class DummyAssistant
  def self.schema
    "{}"
  end

  def self.distribute_tasks(task_plan:, tasking_plans:)
    tasking_plans.collect do |tasking_plan|
      task = FactoryGirl.create :tasks_task, task_plan: task_plan
      FactoryGirl.create(:tasks_tasking, role: tasking_plan.target,
                                         task: task.entity_task)
      task
    end
  end
end
