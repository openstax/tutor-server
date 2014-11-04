FactoryGirl.define do
  factory :interactive do
    resource

    after(:build) do |interactive|
      reading.task_step ||= FactoryGirl.build(:task_step, details: interactive)
    end
  end
end
