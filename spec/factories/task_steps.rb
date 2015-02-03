FactoryGirl.define do
  factory :task_step do
    ignore do
      details_type :reading
    end

    details nil
    task
    number nil
    title { Faker::Lorem.words(3) }
    url { Faker::Internet.url }
    content { Faker::Lorem.paragraphs }

    after(:build) do |task_step, evaluator|
      task_step.details ||= \
        FactoryGirl.build("#{evaluator.details_type.to_s}_step".to_sym,
                          task_step: task_step)
    end
  end
end
