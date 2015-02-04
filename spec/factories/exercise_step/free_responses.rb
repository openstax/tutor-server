FactoryGirl.define do
  factory :exercise_step_free_response, class: ExerciseStep::FreeResponse do
    exercise_step nil

    after(:build) do |fr|
      fr.exercise_step ||= FactoryGirl.build(:exercise_step, step: fr)
    end
  end
end
