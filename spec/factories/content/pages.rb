FactoryGirl.define do
  factory :content_page, class: '::Content::Page' do
    url { Faker::Internet.url }
    association :book, factory: :content_book
    title { Faker::Lorem.words(3) }
  end
end
