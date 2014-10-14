FactoryGirl.define do
  factory :task do
    ignore do 
      opens_at_time Time.now
      duration 1.week
      details_type :reading        # Sets the kind of detailed task
    end

    task_plan nil
    opens_at { opens_at_time }
    due_at { opens_at_time + duration }
    is_shared false
    title "A task"

    after(:build) do |task, evaluator|
      task.details ||= FactoryGirl.build(evaluator.details_type)
    end
  end
end
