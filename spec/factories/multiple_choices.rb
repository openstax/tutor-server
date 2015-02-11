FactoryGirl.define do
  factory :multiple_choice do
    exercise_substep nil
    answer_id 1

    after(:build) do |mc|
      mc.exercise_substep ||= FactoryGirl.build(:exercise_substep,
                                                subtasked: mc)
    end
  end
end
