FactoryGirl.define do
  factory :tasked_reading do
    task_step nil

    after(:build) do |tasked_reading|
      tasked_reading.task_step ||= FactoryGirl.build(:task_step,
                                                     tasked: tasked_reading)
    end
  end
end
