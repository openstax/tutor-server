class DummyAssistant < Tasks::Assistants::GenericAssistant
  def self.schema
    "{}"
  end

  def build_tasks
    roles.map{ build_task(type: :external, default_title: 'Dummy') }
  end


end
