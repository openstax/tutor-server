FactoryGirl.define do
  factory :task_step do
    task
    tasked_type :tasked_reading
    title { Faker::Lorem.sentence(3) }
    url { Faker::Internet.url }
    content { Faker::Lorem.paragraphs.join("\n\n") }

    after(:build) do |task_step, evaluator|
      task_step.tasked ||= \
        FactoryGirl.build(evaluator.tasked_type, task_step: task_step)
    end
  end
end
