FactoryGirl.define do
  factory :content_map, class: ::Content::Models::Map do
    association :from_ecosystem, factory: :content_ecosystem
    association :to_ecosystem, factory: :content_ecosystem
    map { {} }
    is_valid true
  end
end
