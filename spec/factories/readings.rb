FactoryGirl.define do
  factory :reading do
    resource

    after(:build) do |reading|
      reading.task ||= FactoryGirl.build(:task, details: reading)
    end
  end
end
