FactoryGirl.define do
  factory :content_book_part, class: '::Content::Models::BookPart' do
    transient do
      contents {{}}
    end

    title { contents[:title] || Faker::Lorem.words(3).join(" ") }
    association :book, factory: :content_book
    uuid { parent_book_part.nil? ? contents[:uuid] || SecureRandom.uuid : nil }
    version { parent_book_part.nil? ? contents[:version] || "#{Random.rand(1..10)}.#{Random.rand(1..30)}" : nil }
    url { parent_book_part.nil? ? "https://archive.cnx.org/contents/#{uuid}@#{version}" : nil }

    after(:create) do |book_part, evaluator|
      (evaluator.contents[:book_parts] || {}).each do |child_book_part|
        FactoryGirl.create(:content_book_part,
                           contents: child_book_part,
                           chapter_section: child_book_part[:chapter_section],
                           book: book_part.book,
                           parent_book_part: book_part)
      end

      (evaluator.contents[:pages] || {}).each do |page|
        the_page = FactoryGirl.create(:content_page,
                                      title: page[:title],
                                      chapter_section: page[:chapter_section],
                                      book_part: book_part)
        lo_hashes = page[:los].collect{ |lo| { value: lo, type: :lo } }
        tags = Content::Routines::FindOrCreateTags[input: lo_hashes]
        Content::Routines::TagResource[the_page, tags]
      end
    end

    trait :standard_contents_1 do
      contents {{
        title: 'book title',
        book_parts: [
          {
            title: 'unit 1',
            chapter_section: [1],
            book_parts: [
              {
                title: 'chapter 1',
                chapter_section: [1, 1],
                pages: [
                  {
                    title: 'first page',
                    los: ['ost-tag-lo-topic1-lo1', 'ost-tag-lo-topic2-lo2'],
                    chapter_section: [1, 1, 1]
                  },
                  {
                    title: 'second page',
                    los: ['ost-tag-lo-topic2-lo2', 'ost-tag-lo-topic3-lo3'],
                    chapter_section: [1, 1, 2]
                  }
                ]
              },
              {
                title: 'chapter 2',
                chapter_section: [1, 2],
                pages: [
                  {
                    title: 'third page',
                    los: ['ost-tag-lo-topic4-lo4'],
                    chapter_section: [1, 2, 1],
                  }
                ]
              }
            ]
          }
        ]

      }}
    end

  end
end
