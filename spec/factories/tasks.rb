FactoryGirl.define do
  factory :task do
    ignore do
      duration 1.week
      step_types []
      num_taskings 0
    end

    task_plan
    task_type "reading"
    title "A task"
    opens_at { Time.now }
    due_at { opens_at + duration }

    after(:build) do |task, evaluator|
      evaluator.step_types.each_with_index do |type, i|
        step = FactoryGirl.build(:task_step, task: task, number: i)
        step.details = FactoryGirl.build(type, task_step: step)
        task.task_steps << step
      end

      evaluator.num_taskings.times do
        task.taskings << FactoryGirl.build(:tasking, task: task)
      end
    end
  end
end
