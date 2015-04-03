FactoryGirl.define do
  factory :content_exercise, class: '::Content::Models::Exercise' do
    url { Faker::Internet.url }
    title { Faker::Lorem.words(3).join(' ') }
    content { OpenStax::Exercises::V1.fake_client.new_exercise_hash }
  end
end
