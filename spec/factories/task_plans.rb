# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :task_plan do
    ignore do
      num_tasking_plans 1
    end

    association :owner, factory: :klass
    assistant "manual"
    configuration "{}"
    assign_after { Time.now }
    assigned_at nil
    is_ready true

    after(:build) do |task_plan, evaluator|
      evaluator.num_tasking_plans.times do
        task_plan.tasking_plans << FactoryGirl.build(:tasking_plan,
                                                     task_plan: task_plan)
      end
    end
  end
end
