class DummyAssistant < Tasks::Assistants::GenericAssistant
  def self.schema
    "{}"
  end

  def build_tasks
    individualized_tasking_plans.map do |tasking_plan|
      build_task(type: :external, default_title: 'Dummy', time_zone: tasking_plan.time_zone)
    end
  end


end
