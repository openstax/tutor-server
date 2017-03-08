FactoryGirl.define do
  factory :content_book, class: '::Content::Models::Book' do
    transient do
      contents {{}}
    end

    title { contents[:title] || Faker::Lorem.words(3).join(' ') }
    content { contents.to_json }
    uuid { SecureRandom.uuid }
    version { Random.rand(1..10) }
    url { "https://archive.cnx.org/contents/#{uuid}@#{version}" }
    reading_processing_instructions {
      [
        { css: '.ost-reading-discard, .os-teacher, [data-type="glossary"]',
          fragments: [], except: 'snap-lab' },
        { css: '.ost-feature:has-descendants(".os-exercise",2),
                .ost-feature:has-descendants(".ost-exercise-choice"),
                .ost-assessed-feature:has-descendants(".os-exercise",2),
                .ost-assessed-feature:has-descendants(".ost-exercise-choice")',
          fragments: ['node', 'optional_exercise'] },
        { css: '.ost-feature:has-descendants(".os-exercise, .ost-exercise-choice"),
                .ost-assessed-feature:has-descendants(".os-exercise, .ost-exercise-choice")',
          fragments: ['node', 'exercise'] },
        { css: '.ost-feature .ost-exercise-choice, .ost-assessed-feature .ost-exercise-choice,
                .ost-feature .os-exercise, .ost-assessed-feature .os-exercise', fragments: [] },
        { css: '.ost-exercise-choice', fragments: ['exercise', 'optional_exercise'] },
        { css: '.os-exercise', fragments: ['exercise'] },
        { css: '.ost-video', fragments: ['video'] },
        { css: '.os-interactive, .ost-interactive', fragments: ['interactive'] },
        { css: '.worked-example', fragments: ['reading'], labels: ['worked-example'] },
        { css: '.ost-feature, .ost-assessed-feature', fragments: ['reading'] }
      ]
    }

    after(:build) do |book, evaluator|
      book.ecosystem ||= build(:content_ecosystem, comments: Faker::Lorem.words(2).join(' '))
    end

    after(:create) do |book, evaluator|
      (evaluator.contents[:chapters] || {}).each do |chapter|
        create(:content_chapter,
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

    trait :standard_contents_2 do
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
              },
              {
                title: 'fourth page',
                los: ['ost-tag-lo-topic5-lo4'],
                aplos: [],
                book_location: [2, 2],
              }
            ]
          }
        ]
      }}
    end
  end
end
