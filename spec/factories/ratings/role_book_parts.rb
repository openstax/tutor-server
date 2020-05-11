FactoryBot.define do
  factory :ratings_role_book_part, class: '::Ratings::RoleBookPart' do
    association :role, factory: :entity_role

    book_part_uuid { SecureRandom.uuid }
    is_page { [ true, false ].sample }

    num_responses { rand(10) + 1 }

    clue do
      {
        minimum: 0.0,
        most_likely: 0.5,
        maximum: 1.0,
        is_real: false
      }
    end

    glicko_mu { 1.5 }
    glicko_phi { 1.5 }
    glicko_sigma { 1.5 }
  end
end
