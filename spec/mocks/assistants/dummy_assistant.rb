class DummyAssistant < Tasks::Assistants::GenericAssistant
  def self.schema
    "{}"
  end

  def build_tasks
    @taskees.collect do |taskee|
      Tasks::BuildTask[task_plan: @task_plan,
                       title: @task_plan.title,
                       description: @task_plan.description,
                       task_type: :external].entity_task
    end
  end


end
