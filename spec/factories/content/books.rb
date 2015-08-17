FactoryGirl.define do
  factory :content_book, class: '::Content::Models::Book' do
    transient do
      contents {{}}
    end

    url { Faker::Internet.url }
    title { contents[:title] || Faker::Lorem.words(3) }
    content { contents.to_json }
    uuid { SecureRandom.uuid }
    version { Random.rand(1..10) }

    after(:build) do |book, evaluator|
      book.ecosystem ||= FactoryGirl.build(
        :content_ecosystem, title: "#{evaluator.title} (#{evaluator.uuid}@#{evaluator.version})"
      )
    end

    after(:create) do |book, evaluator|
      (evaluator.contents[:chapters] || {}).each do |chapter|
        FactoryGirl.create(:content_chapter,
                           title: chapter[:title],
                           book_location: chapter[:book_location],
                           book: book,
                           contents: chapter)
      end
    end

    trait :standard_contents_1 do
      contents {{
        title: 'book title',
        chapters: [
          {
            title: 'chapter 1',
            book_location: [1],
            pages: [
              {
                title: 'first page',
                los: ['ost-tag-lo-topic1-lo1', 'ost-tag-lo-topic2-lo2'],
                aplos: [],
                book_location: [1, 1]
              },
              {
                title: 'second page',
                los: ['ost-tag-lo-topic2-lo2', 'ost-tag-lo-topic3-lo3'],
                aplos: [],
                book_location: [1, 2]
              }
            ]
          },
          {
            title: 'chapter 2',
            book_location: [2],
            pages: [
              {
                title: 'third page',
                los: ['ost-tag-lo-topic4-lo4'],
                aplos: [],
                book_location: [2, 1],
              }
            ]
          }
        ]

      }}
    end
  end
end
