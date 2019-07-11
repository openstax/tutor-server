class DummyAssistant < Tasks::Assistants::GenericAssistant

  def self.schema
    '{}'
  end

  def build_tasks
    individualized_tasking_plans.map do |tasking_plan|
      build_task(type: :external, default_title: 'Dummy', individualized_tasking_plan: tasking_plan)
    end
  end

end
