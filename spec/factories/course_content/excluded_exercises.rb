FactoryGirl.define do
  factory :excluded_exercise do
    association :course, factory: :entity_course
    number { SecureRandom.hex(4).to_i(16)/2 }
  end
end
