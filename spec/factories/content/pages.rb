FactoryGirl.define do
  factory :content_page, class: '::Content::Models::Page' do
    association :chapter, factory: :content_chapter
    url           { Faker::Internet.url }
    title         { Faker::Lorem.words(3).join(' ') }
    content       { Faker::Lorem.paragraphs(2).join("\n") }
    uuid          { SecureRandom.uuid }
    version       { Random.rand(1..10) }
    book_location [1, 1]
    fragments     []
    snap_labs     []

    association :reading_dynamic_pool, factory: :content_pool
    association :reading_context_pool, factory: :content_pool
    association :homework_core_pool, factory: :content_pool
    association :homework_dynamic_pool, factory: :content_pool
    association :practice_widget_pool, factory: :content_pool
    association :concept_coach_pool, factory: :content_pool
    association :all_exercises_pool, factory: :content_pool
  end
end
