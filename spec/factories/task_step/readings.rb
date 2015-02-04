FactoryGirl.define do
  factory :task_step_reading, class: TaskStep::Reading do
    task_step nil

    after(:build) do |reading|
      reading.task_step ||= FactoryGirl.build(:task_step, step: reading)
    end
  end
end
