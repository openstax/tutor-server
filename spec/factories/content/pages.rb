FactoryBot.define do
  factory :content_page, class: '::Content::Models::Page' do
    association :book, factory: :content_book
    title               { Faker::Lorem.words(3).join(' ') }
    content             { Faker::Lorem.paragraphs(2).join("\n") }
    uuid                { SecureRandom.uuid }
    version             { Random.rand(1..10) }
    url                 { OpenStax::Cnx::V1.archive_url_for "#{uuid}@#{version}" }
    book_indices        { [ [0], [1, 0], [1, 1], [1, 1, 1] ].sample }
    book_location       { [ [], [1, 1] ].sample }
    fragments           { [] }
    snap_labs           { [] }
  end
end
