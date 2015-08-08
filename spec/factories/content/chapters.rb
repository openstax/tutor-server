FactoryGirl.define do
  factory :content_chapter, class: '::Content::Models::Chapter' do
    transient do
      contents {{}}
    end

    title { contents[:title] || Faker::Lorem.words(3).join(" ") }
    association :book, factory: :content_book
    book_location [1]

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

  end
end
