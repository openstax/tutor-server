FactoryBot.define do
  factory :ratings_exercise_group_book_part, class: '::Ratings::ExerciseGroupBookPart' do
    exercise_group_uuid { SecureRandom.uuid }
    book_part_uuid      { SecureRandom.uuid }

    is_page { [ true, false ].sample }

    num_responses { rand(10) + 1 }

    glicko_mu    { 0.0   }
    glicko_phi   { 2.015 }
    glicko_sigma { 0.06  }
  end
end
