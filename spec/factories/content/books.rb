FactoryGirl.define do
  factory :content_book, class: '::Content::Book' do
    title { Faker::Lorem.words(3) }
  end
end
