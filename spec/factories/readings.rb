FactoryGirl.define do
  factory :reading do
    task_step nil

    after(:build) do |reading|
      reading.task_step ||= FactoryGirl.build(:task_step, details: reading)
    end
  end
end
