FactoryGirl.define do
  factory :interactive do
    resource

    after(:build) do |interactive|
      interactive.task_step ||= FactoryGirl.build(:task_step,
                                                  details: interactive)
    end
  end
end
