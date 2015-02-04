FactoryGirl.define do
  factory :task_step do
    step_type :reading
    task
    title { Faker::Lorem.words(3) }
    url { Faker::Internet.url }
    content { Faker::Lorem.paragraphs }

    after(:build) do |task_step, evaluator|
      task_step.step ||= \
        FactoryGirl.build("#{evaluator.step_type.to_s}_step".to_sym,
                          task_step: task_step)
    end
  end
end
