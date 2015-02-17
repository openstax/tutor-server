class EmptyClass; end

FactoryGirl.define do
  factory :assistant do
    study nil
    code_class_name "EmptyClass"
    settings nil
    data nil
  end
end
