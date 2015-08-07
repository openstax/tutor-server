FactoryGirl.define do
  factory :content_chapter, class: '::Content::Models::Chapter' do
    transient do
      contents {{}}
    end

    title { contents[:title] || Faker::Lorem.words(3).join(" ") }
    association :book, factory: :content_book
    uuid { contents[:uuid] || SecureRandom.uuid }
    version { contents[:version] || "#{Random.rand(1..10)}.#{Random.rand(1..30)}" }
    url { "https://archive.cnx.org/contents/#{uuid}@#{version}" }

    after(:create) do |chapter, evaluator|
      (evaluator.contents[:pages] || {}).each do |page|
        the_page = FactoryGirl.create(:content_page,
                                      title: page[:title],
                                      book_location: page[:book_location],
                                      chapter: chapter)
        lo_hashes = page[:los].collect{ |lo| { value: lo, type: :lo } }
        aplo_hashes = page[:aplos].collect{ |lo| { value: lo, type: :aplo } }
        tags = Content::Routines::FindOrCreateTags[input: lo_hashes + aplo_hashes]
        Content::Routines::TagResource[the_page, tags]
      end
    end

    trait :standard_contents_1 do
      contents {{
        title: 'book title',
        chapters: [
          {
            title: 'chapter 1',
            book_location: [1, 1],
            pages: [
              {
                title: 'first page',
                los: ['ost-tag-lo-topic1-lo1', 'ost-tag-lo-topic2-lo2'],
                aplos: [],
                book_location: [1, 1, 1]
              },
              {
                title: 'second page',
                los: ['ost-tag-lo-topic2-lo2', 'ost-tag-lo-topic3-lo3'],
                aplos: [],
                book_location: [1, 1, 2]
              }
            ]
          },
          {
            title: 'chapter 2',
            book_location: [1, 2],
            pages: [
              {
                title: 'third page',
                los: ['ost-tag-lo-topic4-lo4'],
                aplos: [],
                book_location: [1, 2, 1],
              }
            ]
          }
        ]

      }}
    end

  end
end
