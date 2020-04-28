FactoryBot.define do
  factory :cache_role_book_part, class: '::Cache::RoleBookPart' do
    association :role, factory: :entity_role

    book_part_uuid { SecureRandom.uuid }
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
