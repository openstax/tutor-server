FactoryBot.define do
  factory :content_map, class: ::Content::Models::Map do
    association :from_ecosystem, factory: :content_ecosystem
    association :to_ecosystem, factory: :content_ecosystem
    exercise_id_to_page_id_map({})
    page_id_to_page_id_map({})
    page_id_to_pool_type_exercise_ids_map({})
    is_valid true
    validity_error_messages []
  end
end
