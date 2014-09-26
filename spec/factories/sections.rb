FactoryGirl.define do
  factory :section do
    klass
    sequence(:name) {|n| "Section #{n}" }
  end
end
