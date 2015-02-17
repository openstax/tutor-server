FactoryGirl.define do
  factory :tasked_reading do
    transient do
      skip_task false
    end

    task_step nil

    after(:build) do |tasked_reading, evaluator|
      options = { tasked: tasked_reading }
      options[:task] = nil if evaluator.skip_task

      tasked_reading.task_step ||= FactoryGirl.build(:task_step, options)
    end
  end
end
