FactoryGirl.define do
  factory :reading_step do
    task_step nil

    after(:build) do |rs|
      rs.task_step ||= FactoryGirl.build(:task_step, step: rs)
    end
  end
end
