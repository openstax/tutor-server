FactoryGirl.define do
  factory :content_book_part, class: '::Content::BookPart' do
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
        the_page = FactoryGirl.create(:content_page, title: page[:title], book_part: book_part)
        Content::TagResourceWithTopics[the_page, page[:topics]]
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
                    topics: ['ost-tag-lo-topic1-lo1', 'ost-tag-lo-topic2-lo2']
                  },
                  { 
                    title: 'second page',
                    topics: ['ost-tag-lo-topic2-lo2', 'ost-tag-lo-topic3-lo3']
                  }
                ]
              },
              {
                title: 'chapter 2',
                pages: [
                  { 
                    title: 'third page',
                    topics: ['ost-tag-lo-topic4-lo4']
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

