FactoryBot.define do
  factory :tasks_tasked_interactive, class: '::Tasks::Models::TaskedInteractive' do
    transient do
      skip_task false
    end

    task_step nil
    url { Faker::Internet.url }
    title { Faker::Lorem.sentence(3) }

    after(:build) do |tasked_interactive, evaluator|
      options = { tasked: tasked_interactive, skip_task: evaluator.skip_task }

      tasked_interactive.task_step ||= FactoryBot.build(:tasks_task_step, options)
    end
  end
end
