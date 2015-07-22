FactoryGirl.define do
  factory :district, class: CourseDetail::Models::District do
    sequence(:name) { |n| "FactoryGirl District #{n}" }
  end
end
