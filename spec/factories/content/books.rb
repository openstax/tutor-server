FactoryGirl.define do
  factory :content_book, class: '::Content::Models::Book' do
    association :ecosystem, factory: :content_ecosystem
  end
end
