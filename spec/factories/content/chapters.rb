FactoryGirl.define do
  factory :content_chapter, class: '::Content::Models::Chapter' do
    transient do
      contents {{}}
    end

    association :book, factory: :content_book

    title { Faker::Lorem.words(3).join(' ') }
    book_location [1]

    after(:create) do |chapter, evaluator|
      ecosystem = evaluator.book.ecosystem
      (evaluator.contents[:pages] || {}).each do |page|
        the_page = FactoryGirl.create(:content_page,
                                      title: page[:title],
                                      book_location: page[:book_location],
                                      chapter: chapter)
        lo_hashes = page[:los].map{ |lo| { value: lo, type: :lo } }
        aplo_hashes = page[:aplos].map{ |lo| { value: lo, type: :aplo } }
        tags = Content::Routines::FindOrCreateTags[ecosystem: ecosystem,
                                                   input: lo_hashes + aplo_hashes]
        Content::Routines::TagResource[the_page, tags]
        chapter.all_exercises_pool ||= FactoryGirl.create :content_pool, ecosystem: ecosystem
      end
    end

  end
end
