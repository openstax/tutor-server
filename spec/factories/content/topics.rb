FactoryGirl.define do
  sequence :topic_name do |n| "Topic #{n}" end

  factory :content_topic, class: '::Content::Topic' do
    name { generate(:topic_name) }
  end
end
