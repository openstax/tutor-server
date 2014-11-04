FactoryGirl.define do
  factory :task do
    ignore do
      duration 1.week
      late_duration 1.week
      num_steps 0
      num_taskings 0
    end

    task_plan
    title "A task"
    opens_at { Time.now }
    due_at { opens_at + duration }
    closes_at { opens_at + duration + late_duration }

    after(:build) do |task, evaluator|
      evaluator.num_steps.times do
        task.task_steps << FactoryGirl.build(:task_step, task: task)
      end

      evaluator.num_taskings.times do
        task.taskings << FactoryGirl.build(:tasking, task: task)
      end
    end
  end
end
