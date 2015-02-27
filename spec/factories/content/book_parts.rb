FactoryGirl.define do
  factory :content_book_part, class: '::Content::BookPart' do
    title { Faker::Lorem.words(3) }
  end
end
