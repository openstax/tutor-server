# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :task_step do
    ignore do
      details_type :reading
    end

    task
    details nil
    number nil

    after(:build) do |task_step, evaluator|
      task_step.details ||= FactoryGirl.build(evaluator.details_type,
                                              task_step: task_step)
    end
  end
end
