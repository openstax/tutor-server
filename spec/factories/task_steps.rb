FactoryGirl.define do
  factory :task_step do
    task
    tasked_type :tasked_reading

    transient do
      url nil
      content nil
      title nil
    end

    after(:build) do |task_step, evaluator|
      options = { task_step: task_step, url: evaluator.url,
                  content: evaluator.content, title: evaluator.title }
      task_step.tasked ||= \
        FactoryGirl.build(evaluator.tasked_type, options.compact)
    end
  end
end
