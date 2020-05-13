FactoryBot.define do
  factory :ratings_role_book_part, class: '::Ratings::RoleBookPart' do
    association :role, factory: :entity_role

    book_part_uuid { SecureRandom.uuid }
    is_page { [ true, false ].sample }

    glicko_mu    { 0.0   }
    glicko_phi   { 2.015 }
    glicko_sigma { 0.06  }

    tasked_exercise_ids { [] }

    clue do
      {
        minimum: 0.0,
        most_likely: 0.5,
        maximum: 1.0,
        is_real: false
      }
    end
  end
end
