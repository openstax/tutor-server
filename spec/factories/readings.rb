FactoryGirl.define do
  factory :reading do
    resource

    after(:build) do |reading|
      reading.task_step ||= FactoryGirl.build(:task_step, details: reading)
    end
  end
end
