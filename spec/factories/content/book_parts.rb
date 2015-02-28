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
  end
end
