FactoryGirl.define do
  factory :tasked_video do
    transient do
      skip_task false
    end

    task_step nil
    url { Faker::Internet.url }
    title { Faker::Lorem.sentence(3) }
    content { Faker::Lorem.paragraph }
    video_url { Faker::Internet.url }

    after(:build) do |tasked_video, evaluator|
      options = { tasked: tasked_video }
      options[:task] = nil if evaluator.skip_task

      tasked_video.task_step ||= FactoryGirl.build(:task_step, options)
    end
  end
end
