FactoryGirl.define do
  factory :exercise do
    task_step nil

    after(:build) do |exercise|
      exercise.task_step ||= FactoryGirl.build(:task_step, details: exercise)
    end
  end
end
