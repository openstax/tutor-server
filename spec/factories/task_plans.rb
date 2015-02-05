FactoryGirl.define do
  factory :task_plan do
    transient do
      duration 1.week
      num_tasking_plans 0
    end

    association :owner, factory: :klass
    assistant
    configuration {{}}
    opens_at { Time.now }
    due_at { opens_at + duration }
    type "study"

    after(:build) do |task_plan, evaluator|
      evaluator.num_tasking_plans.times do
        task_plan.tasking_plans << FactoryGirl.build(:tasking_plan,
                                                     task_plan: task_plan)
      end
    end
  end
end
