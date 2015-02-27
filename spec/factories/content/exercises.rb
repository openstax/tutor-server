FactoryGirl.define do
  factory :content_exercise, class: '::Content::Exercise' do
    url { Faker::Internet.url }
    title { Faker::Lorem.words(3) }
  end
end
