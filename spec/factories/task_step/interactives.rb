FactoryGirl.define do
  factory :task_step_interactive, class: TaskStep::Interactive do
    task_step nil

    after(:build) do |interactive|
      interactive.task_step ||= FactoryGirl.build(:task_step,
                                                  step: interactive)
    end
  end
end
