FactoryGirl.define do
  factory :section do
    course
    sequence(:name) {|n| "Section #{n}" }
  end
end
