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
        FactoryGirl.create(:content_page, title: page[:title], book_part: book_part)
      end
    end

    trait :standard_contents_1 do
      contents {{
        title: 'unit 1',
        book_parts: [
          {
            title: 'chapter 1',
            pages: [
              { title: 'first page' },
              { title: 'second page' }
            ]
          },
          {
            title: 'chapter 2',
            pages: [
              { title: 'third page' }
            ]
          }
        ]
      }}
    end
  end
end

