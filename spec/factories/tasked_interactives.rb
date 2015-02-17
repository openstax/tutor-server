FactoryGirl.define do
  factory :tasked_interactive do
    transient do
      skip_task false
    end

    task_step nil

    after(:build) do |tasked_interactive, evaluator|
      options = { tasked: tasked_interactive }
      options[:task] = nil if evaluator.skip_task

      tasked_interactive.task_step ||= FactoryGirl.build(:task_step, options)
    end
  end
end
