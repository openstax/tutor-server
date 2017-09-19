FactoryGirl.define do
  factory :lms_tool_consumer, class: '::Lms::Models::ToolConsumer' do
    guid { SecureRandom.uuid }
  end
end
