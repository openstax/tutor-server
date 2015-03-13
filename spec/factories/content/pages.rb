FactoryGirl.define do
  factory :content_page, class: '::Content::Page' do
    url { Faker::Internet.url }
    association :book_part, factory: :content_book_part
    title { Faker::Lorem.words(3) }
    content { Faker::Lorem.paragraphs(2) }
  end
end
