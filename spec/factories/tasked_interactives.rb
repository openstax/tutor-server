FactoryGirl.define do
  factory :tasked_interactive do
    task_step nil

    after(:build) do |tasked_interactive|
      tasked_interactive.task_step ||= FactoryGirl.build(
        :task_step, tasked: tasked_interactive
      )
    end
  end
end
