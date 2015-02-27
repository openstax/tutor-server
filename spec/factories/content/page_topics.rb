FactoryGirl.define do
  factory :content_page_topic, class: '::Content::PageTopic' do
    content_page
    content_topic
  end
end
