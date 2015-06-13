FactoryGirl.define do
  factory :tasks_task_plan, class: '::Tasks::Models::TaskPlan' do
    transient do
      duration 1.week
      opens_at { Time.now }
      due_at   { opens_at + duration }
      num_tasking_plans 0
      assistant_code_class_name "DummyAssistant"
    end

    association :owner, factory: :entity_course
    settings { {}.to_json }
    type "reading"

    after(:build) do |task_plan, evaluator|
      code_class_name_hash = {
        code_class_name: evaluator.assistant_code_class_name
      }
      task_plan.assistant ||= Tasks::Models::Assistant.find_by(code_class_name_hash) || \
                              FactoryGirl.build(:tasks_assistant, code_class_name_hash)

      evaluator.num_tasking_plans.times do
        task_plan.tasking_plans << FactoryGirl.build(:tasks_tasking_plan,
                                                     task_plan: task_plan,
                                                     opens_at: evaluator.opens_at,
                                                     due_at: evaluator.due_at)
      end
    end
  end
end
