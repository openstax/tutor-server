FactoryGirl.define do
  factory :content_page, class: '::Content::Models::Page' do
    url { Faker::Internet.url }
    association :chapter, factory: :content_chapter
    title { Faker::Lorem.words(3) }
    content { Faker::Lorem.paragraphs(2) }
    uuid { SecureRandom.uuid }
    version { Random.rand(1..10) }
    book_location [1, 1]

    association :reading_dynamic_pool, factory: :content_pool
    association :reading_try_another_pool, factory: :content_pool
    association :homework_core_pool, factory: :content_pool
    association :homework_dynamic_pool, factory: :content_pool
    association :practice_widget_pool, factory: :content_pool
  end
end
