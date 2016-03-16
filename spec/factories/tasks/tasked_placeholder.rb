FactoryGirl.define do
  factory :tasks_tasked_placeholder, class: '::Tasks::Models::TaskedPlaceholder' do
    transient do
      skip_task false
    end

    task_step nil

    after(:build) do |tasked_placeholder, evaluator|
      options = { tasked: tasked_placeholder, group_type: :personalized_group }
      options[:task] = nil if evaluator.skip_task

      tasked_placeholder.task_step ||= FactoryGirl.build(:tasks_task_step, options)
    end
  end
end
