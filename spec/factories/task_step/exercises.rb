FactoryGirl.define do
  factory :task_step_exercise, class: TaskStep::Exercise do
    task_step nil

    after(:build) do |exercise|
      exercise.task_step ||= FactoryGirl.build(:task_step, step: exercise)
    end
  end
end
