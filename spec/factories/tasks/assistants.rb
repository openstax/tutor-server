require_relative '../../mocks/assistants/dummy_assistant'

FactoryGirl.define do
  factory :tasks_assistant, class: '::Tasks::Models::Assistant' do
    name { Faker::Name.name }
    code_class_name "DummyAssistant"
  end
end
