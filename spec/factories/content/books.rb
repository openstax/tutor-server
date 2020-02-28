FactoryBot.define do
  factory :content_book, class: '::Content::Models::Book' do
    association :ecosystem, factory: :content_ecosystem

    title      { Faker::Lorem.words(3).join(' ') }
    uuid       { SecureRandom.uuid }
    version    { Random.rand(1..10) }
    short_id   { SecureRandom.urlsafe_base64(8).first(8) }
    tutor_uuid { SecureRandom.uuid }
    url        { "https://archive.cnx.org/contents/#{uuid}@#{version}" }
    reading_processing_instructions {
      [
        {
          css: '.ost-reading-discard, .os-teacher, [data-type="glossary"]',
          fragments: [],
          except: ['snap-lab']
        },
        {
          fragments: ['node', 'optional_exercise'],
          css: <<~CSS.strip
            .ost-feature:has-descendants(".os-exercise",2),
            .ost-feature:has-descendants(".ost-exercise-choice"),
            .ost-assessed-feature:has-descendants(".os-exercise",2),
            .ost-assessed-feature:has-descendants(".ost-exercise-choice")
          CSS
        },
        {
          fragments: ['node', 'exercise'],
          css: <<~CSS.strip
            .ost-feature:has-descendants(".os-exercise, .ost-exercise-choice"),
            .ost-assessed-feature:has-descendants(".os-exercise, .ost-exercise-choice")
          CSS
        },
        {
          fragments: [],
          css: <<~CSS.strip
            .ost-feature .ost-exercise-choice,
            .ost-assessed-feature .ost-exercise-choice,
            .ost-feature .os-exercise,
            .ost-assessed-feature .os-exercise
          CSS
        },
        { css: '.ost-exercise-choice', fragments: ['exercise', 'optional_exercise'] },
        { css: '.os-exercise', fragments: ['exercise'] },
        { css: '.ost-video', fragments: ['video'] },
        { css: '.os-interactive, .ost-interactive', fragments: ['interactive'] },
        { css: '.worked-example', fragments: ['reading'], labels: ['worked-example'] },
        { css: '.ost-feature, .ost-assessed-feature', fragments: ['reading'] }
      ]
    }
    tree do
      {
        type: 'Book',
        title: title,
        book_location: [],
        uuid: uuid,
        version: version,
        short_id: short_id,
        tutor_uuid: tutor_uuid,
        children: []
      }
    end
    content { tree.to_json }

    after(:build) do |book, evaluator|
      children = book.children.reverse
      while !children.empty? do
        child = children.pop
        if child.is_a?(Content::Page)
          attributes = { book: book, book_location: [] }
          [ :id, :uuid, :version, :tutor_uuid, :title, :book_location ].each do |attr|
            val = child.public_send(attr)
            attributes[attr] = val unless val.nil?
          end

          book.pages << build(:content_page, attributes)
        else
          children.concat child.children.reverse
        end
      end
    end

    after(:create) do |book, evaluator|
      index = 0
      children = book.tree['children'].reverse
      while !children.empty? do
        child = children.pop
        if child['type'].downcase == 'page'
          child['id'] = evaluator.pages[index].id
          index += 1
        else
          children.concat child['children'].reverse
        end
      end
      book.save!
    end

    transient do
      empty_exercise_pools do
        {}.tap do |pools|
          Content::Models::Page::EXERCISE_ID_FIELDS.each do |field|
            pools[field] = []
          end
        end
      end
    end

    trait :standard_contents_1 do
      tree do
        {
          type: 'Book',
          title: title,
          book_location: [],
          uuid: uuid,
          version: version,
          short_id: short_id,
          tutor_uuid: tutor_uuid,
          children: [
            {
              type: 'Chapter',
              title: 'chapter 1',
              book_location: [1],
              uuid: SecureRandom.uuid,
              version: (rand(10) + 1).to_s,
              short_id: SecureRandom.urlsafe_base64(8).first(8),
              tutor_uuid: SecureRandom.uuid,
              children: [
                empty_exercise_pools.merge(
                  type: 'Page',
                  title: 'first page',
                  book_location: [1, 1],
                  uuid: SecureRandom.uuid,
                  version: (rand(10) + 1).to_s,
                  short_id: SecureRandom.urlsafe_base64(8).first(8),
                  tutor_uuid: SecureRandom.uuid
                ),
                empty_exercise_pools.merge(
                  type: 'Page',
                  title: 'second page',
                  book_location: [1, 2],
                  uuid: SecureRandom.uuid,
                  version: (rand(10) + 1).to_s,
                  short_id: SecureRandom.urlsafe_base64(8).first(8),
                  tutor_uuid: SecureRandom.uuid
                )
              ]
            },
            {
              type: 'Chapter',
              title: 'chapter 2',
              book_location: [2],
              uuid: SecureRandom.uuid,
              version: (rand(10) + 1).to_s,
              short_id: SecureRandom.urlsafe_base64(8).first(8),
              tutor_uuid: SecureRandom.uuid,
              children: [
                empty_exercise_pools.merge(
                  type: 'Page',
                  title: 'third page',
                  book_location: [2, 1],
                  uuid: SecureRandom.uuid,
                  version: (rand(10) + 1).to_s,
                  short_id: SecureRandom.urlsafe_base64(8).first(8),
                  tutor_uuid: SecureRandom.uuid
                )
              ]
            }
          ]
        }
      end
    end

    trait :standard_contents_2 do
      tree do
        {
          type: 'Book',
          title: title,
          book_location: [],
          uuid: uuid,
          version: version,
          short_id: short_id,
          tutor_uuid: tutor_uuid,
          children: [
            {
              type: 'Chapter',
              title: 'chapter 1',
              book_location: [1],
              uuid: SecureRandom.uuid,
              version: (rand(10) + 1).to_s,
              short_id: SecureRandom.urlsafe_base64(8).first(8),
              tutor_uuid: SecureRandom.uuid,
              children: [
                empty_exercise_pools.merge(
                  type: 'Page',
                  title: 'first page',
                  book_location: [1, 1],
                  uuid: SecureRandom.uuid,
                  version: (rand(10) + 1).to_s,
                  short_id: SecureRandom.urlsafe_base64(8).first(8),
                  tutor_uuid: SecureRandom.uuid
                ),
                empty_exercise_pools.merge(
                  type: 'Page',
                  title: 'second page',
                  book_location: [1, 2],
                  uuid: SecureRandom.uuid,
                  version: (rand(10) + 1).to_s,
                  short_id: SecureRandom.urlsafe_base64(8).first(8),
                  tutor_uuid: SecureRandom.uuid
                )
              ]
            },
            {
              type: 'Chapter',
              title: 'chapter 2',
              book_location: [2],
              uuid: SecureRandom.uuid,
              version: (rand(10) + 1).to_s,
              short_id: SecureRandom.urlsafe_base64(8).first(8),
              tutor_uuid: SecureRandom.uuid,
              children: [
                empty_exercise_pools.merge(
                  type: 'Page',
                  title: 'third page',
                  book_location: [2, 1],
                  uuid: SecureRandom.uuid,
                  version: (rand(10) + 1).to_s,
                  short_id: SecureRandom.urlsafe_base64(8).first(8),
                  tutor_uuid: SecureRandom.uuid
                ),
                empty_exercise_pools.merge(
                  type: 'Page',
                  title: 'fourth page',
                  book_location: [2, 2],
                  uuid: SecureRandom.uuid,
                  version: (rand(10) + 1).to_s,
                  short_id: SecureRandom.urlsafe_base64(8).first(8),
                  tutor_uuid: SecureRandom.uuid
                )
              ]
            }
          ]
        }
      end
    end
  end
end
