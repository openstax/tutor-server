FactoryGirl.define do
  factory :content_page_topic, class: '::Content::PageTopic' do
    page
    topic
  end
end
