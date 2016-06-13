FactoryGirl.define do
  factory :content_map, class: ::Content::Models::Map do
    association :from_ecosystem, factory: :content_ecosystem
    association :to_ecosystem, factory: :content_ecosystem
    page_id_to_pages_map { {} }
    pool_type_page_id_to_exercises_map { {} }
    exercise_id_to_page_map { {} }
    is_valid true
  end
end
