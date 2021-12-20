FactoryBot.define do
  factory :tasks_previous_attempt, class: 'Tasks::Models::PreviousAttempt' do
    association :tasked_exercise, factory: :tasks_tasked_exercise

    number        { tasked_exercise.attempt_number }
    attempted_at  { Time.current }

    free_response { Faker::Lorem.paragraph }
    answer_id     { tasked_exercise.answer_ids.sample }

    after(:build) { |previous_attempt| previous_attempt.tasked_exercise.attempt_number += 1 }
  end
end
