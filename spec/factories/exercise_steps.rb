FactoryGirl.define do
  factory :exercise_step do
    task_step nil

    after(:build) do |es|
      es.task_step ||= FactoryGirl.build(:task_step, step: es)
    end
  end
end
