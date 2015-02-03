FactoryGirl.define do
  factory :task_step do
    ignore do
      details_type :reading
    end

    details nil
    resource
    task
    number nil
    title { Faker::Lorem.words(3) }

    after(:build) do |task_step, evaluator|
      task_step.details ||= FactoryGirl.build(evaluator.details_type,
                                              task_step: task_step)
    end
  end
end
