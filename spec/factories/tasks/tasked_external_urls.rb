FactoryBot.define do
  factory :tasks_tasked_external_url, class: '::Tasks::Models::TaskedExternalUrl' do
    transient do
      skip_task { false }
    end

    task_step { nil }
    url { Faker::Internet.url }
    title { Faker::Lorem.sentence(3) }

    after(:build) do |tasked_external_url, evaluator|
      options = { tasked: tasked_external_url, skip_task: evaluator.skip_task }

      tasked_external_url.task_step ||= FactoryBot.build(:tasks_task_step, options)
    end
  end
end
