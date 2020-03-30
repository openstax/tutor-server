FactoryBot.define do
  factory :tasks_tasked_reading, class: '::Tasks::Models::TaskedReading' do
    transient      do
      skip_task      { false }
      fragment_index { task_step&.fragment_index || 0 }
    end

    task_step      { nil }
    url            { Faker::Internet.url }
    title          { Faker::Lorem.sentence(3) }
    book_location  { [ [ rand(1..10), rand(1..10) ], [] ].sample }

    after(:build) do |tasked_reading, evaluator|
      options = { tasked: tasked_reading, skip_task: evaluator.skip_task }

      tasked_reading.task_step ||= FactoryBot.build :tasks_task_step, options
      tasked_reading.task_step.fragment_index = evaluator.fragment_index
    end
  end
end
