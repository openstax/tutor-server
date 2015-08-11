FactoryGirl.define do
  factory :content_ecosystem, class: '::Content::Models::Ecosystem' do
    title { books.first.try(:title) || Faker::Lorem.words(3).join(" ") }
  end
end
