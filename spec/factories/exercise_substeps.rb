FactoryGirl.define do
  factory :exercise_substep do
    tasked_exercise
    subtasked_type :multiple_choice

    after(:build) do |exercise_substep, evaluator|
      exercise_substep.subtasked ||= FactoryGirl.build(
        evaluator.subtasked_type, exercise_substep: exercise_substep
      )
    end
  end
end
