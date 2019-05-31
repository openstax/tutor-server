FactoryBot.define do
  factory :tasks_tasked_reading, class: '::Tasks::Models::TaskedReading' do
    transient           { skip_task { false } }

    task_step           { nil }
    url                 { Faker::Internet.url }
    title               { Faker::Lorem.sentence(3) }
    book_location       { [rand(1..10), rand(1..10)] }
    baked_book_location { [ book_location, [] ].sample }
    content             { Faker::Lorem.paragraph }

    after(:build) do |tasked_reading, evaluator|
      options = { tasked: tasked_reading, skip_task: evaluator.skip_task }

      tasked_reading.task_step ||= FactoryBot.build(:tasks_task_step, options)
    end
  end
end
