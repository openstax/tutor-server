FactoryBot.define do
  factory :content_page, class: '::Content::Models::Page' do
    association :book, factory: :content_book
    title                 { Faker::Lorem.words(3).join(' ') }
    content               { Faker::Lorem.paragraphs(2).join("\n") }
    uuid                  { SecureRandom.uuid }
    version               { Random.rand(1..10) }
    url                   { OpenStax::Content::Archive.new('1.0').url_for "#{uuid}@#{version}" }
    parent_book_part_uuid { SecureRandom.uuid }
    book_indices          { [ [0], [1, 0], [1, 1], [1, 1, 1] ].sample }
    book_location         { [ [], [1, 1] ].sample }
    snap_labs             { [] }

    after(:create) do |page|
      Content::Routines::TransformAndCachePageContent.call book: page.book, pages: [ page ]
    end
  end
end
