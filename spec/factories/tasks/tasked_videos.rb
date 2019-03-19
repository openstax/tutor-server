FactoryBot.define do
  factory :tasks_tasked_video, class: '::Tasks::Models::TaskedVideo' do
    transient do
      skip_task { false }
    end

    task_step { nil }
    url { Faker::Internet.url }
    title { Faker::Lorem.sentence(3) }
    content { Faker::Lorem.paragraph }

    after(:build) do |tasked_video, evaluator|
      options = { tasked: tasked_video, skip_task: evaluator.skip_task }

      tasked_video.task_step ||= FactoryBot.build(:tasks_task_step, options)
    end
  end
end
