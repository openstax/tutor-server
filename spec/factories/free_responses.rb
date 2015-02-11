FactoryGirl.define do
  factory :free_response do
    exercise_substep nil

    after(:build) do |fr|
      fr.exercise_substep ||= FactoryGirl.build(:exercise_substep,
                                                subtasked: fr)
    end
  end
end
