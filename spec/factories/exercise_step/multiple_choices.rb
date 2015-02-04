FactoryGirl.define do
  factory :exercise_step_multiple_choice,
          class: ExerciseStep::MultipleChoice do
    exercise_step nil
    answer_id 1

    after(:build) do |mc|
      mc.exercise_step ||= FactoryGirl.build(:exercise_step, step: mc)
    end
  end
end
