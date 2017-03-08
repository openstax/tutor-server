FactoryGirl.define do
  factory :content_ecosystem, class: '::Content::Models::Ecosystem' do
    comments { Faker::Lorem.words(2).join(' ') }
  end
end
