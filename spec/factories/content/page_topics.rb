FactoryGirl.define do
  factory :content_page_topic, class: '::Content::Models::PageTopic' do
    association :page, factory: :content_page
    association :topic, factory: :content_topic
  end
end
