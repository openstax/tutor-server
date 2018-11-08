FactoryBot.define do
  factory :tasks_tasked_placeholder, class: '::Tasks::Models::TaskedPlaceholder' do
    transient do
      skip_task false
    end

    task_step nil

    after(:build) do |tasked_placeholder, evaluator|
      options = {
        tasked: tasked_placeholder,
        group_type: :personalized_group,
        skip_task: evaluator.skip_task
      }

      tasked_placeholder.task_step ||= FactoryBot.build(:tasks_task_step, options)
    end
  end
end
