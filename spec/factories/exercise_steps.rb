FactoryGirl.define do
  factory :exercise_step do
    association :exercise, factory: :task_step_exercise
    step_type :multiple_choice

    after(:build) do |exercise_step, evaluator|
      exercise_step.step ||= \
        FactoryGirl.build("exercise_step_#{evaluator.step_type.to_s}".to_sym,
                          exercise_step: exercise_step)
    end
  end
end
