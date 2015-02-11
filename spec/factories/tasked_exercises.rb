FactoryGirl.define do
  factory :tasked_exercise do
    task_step nil

    after(:build) do |tasked_exercise|
      tasked_exercise.task_step ||= FactoryGirl.build(:task_step,
                                                      tasked: tasked_exercise)
    end
  end
end
