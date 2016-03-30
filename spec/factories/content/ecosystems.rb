FactoryGirl.define do
  factory :content_ecosystem, class: '::Content::Models::Ecosystem' do
    title       { Faker::Lorem.words(3).join(" ") }
    archive_url { OpenStax::Cnx::V1.archive_url_base }
  end
end
