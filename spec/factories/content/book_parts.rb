FactoryGirl.define do
  factory :content_book_part, class: '::Content::Models::BookPart' do
    transient do
      contents {{}}
    end

    title { contents[:title] || Faker::Lorem.words(3).join(" ") }
    association :book, factory: :entity_book

    after(:create) do |book_part, evaluator|
      (evaluator.contents[:book_parts] || {}).each do |child_book_part|
        FactoryGirl.create(:content_book_part,
                           contents: child_book_part,
                           book: book_part.book,
                           parent_book_part: book_part)
      end

      (evaluator.contents[:pages] || {}).each do |page|
        the_page = FactoryGirl.create(:content_page,
                                      title: page[:title],
                                      chapter_section: page[:chapter_section],
                                      book_part: book_part)
        Content::Routines::TagResource[the_page, page[:los]]
      end
    end

    trait :standard_contents_1 do
      contents {{
        title: 'root',
        book_parts: [
          {
            title: 'unit 1',
            book_parts: [
              {
                title: 'chapter 1',
                pages: [
                  {
                    title: 'first page',
                    los: ['ost-tag-lo-topic1-lo1', 'ost-tag-lo-topic2-lo2'],
                    chapter_section: '1.1'
                  },
                  {
                    title: 'second page',
                    los: ['ost-tag-lo-topic2-lo2', 'ost-tag-lo-topic3-lo3'],
                    chapter_section: '1.2'
                  }
                ]
              },
              {
                title: 'chapter 2',
                pages: [
                  {
                    title: 'third page',
                    los: ['ost-tag-lo-topic4-lo4'],
                    chapter_section: '1.3'
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
