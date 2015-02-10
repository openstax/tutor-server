FactoryGirl.define do
  sequence :topic_name do |n| "Topic #{n}" end

  factory :topic do
    name { generate(:topic_name) }
  end
end
