FactoryBot.define do
  factory :ratings_exercise_group_book_part, class: '::Ratings::ExerciseGroupBookPart' do
    exercise_group_uuid { SecureRandom.uuid }
    book_part_uuid      { SecureRandom.uuid }

    is_page { [ true, false ].sample }

    num_responses { rand(10) + 1 }

    glicko_mu { 1.5 }
    glicko_phi { 1.5 }
    glicko_sigma { 1.5 }
  end
end
