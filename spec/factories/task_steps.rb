FactoryGirl.define do
  factory :task_step do
    task
    step_type :reading
    title { Faker::Lorem.words(3) }
    url { Faker::Internet.url }
    content { Faker::Lorem.paragraphs }

    after(:build) do |task_step, evaluator|
      task_step.step ||= \
        FactoryGirl.build("task_step_#{evaluator.step_type.to_s}".to_sym,
                          task_step: task_step)
    end
  end
end
