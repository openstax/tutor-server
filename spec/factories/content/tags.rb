FactoryGirl.define do
  sequence :value do |n| "Tag #{n}" end

  factory :content_tag, class: '::Content::Models::Tag' do
    value { generate(:value) }
    name { Faker::Lorem.word }
    description { Faker::Lorem.paragraph }
  end
end
