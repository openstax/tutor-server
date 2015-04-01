class DummyAssistant
  def self.schema
    "{}"
  end

  def self.distribute_tasks(task_plan:, taskees:)
    taskees.collect do |taskee|
      FactoryGirl.create(:tasks_tasking, user: taskee, taskee: taskee).task
    end
  end
end
