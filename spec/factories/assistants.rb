# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :assistant do
    study nil # Study NYI
    code_class_name "DummyAssistant"
    settings nil
    data nil
  end
end
