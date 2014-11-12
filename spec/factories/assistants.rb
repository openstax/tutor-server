class SpecDummyAssistant < AssistantBase
  configure schema: {}

  supports_task_plan type: :study, schema: {}
  supports_task_plan type: :homework, schema: {}

  def task_taskees(task_plan, taskees)
  end

  def validate_task_plan(task_plan)
    []
  end
end

FactoryGirl.define do
  factory :assistant do
    study nil
    code_class_name "SpecDummyAssistant"
    settings nil
    data nil
  end
end
