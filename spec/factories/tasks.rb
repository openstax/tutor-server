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
        task_step = FactoryGirl.build(:task_step, task: task, number: i)
        task_step.step = FactoryGirl.build(type, task_step: task_step)
        task.task_steps << task_step
      end

      evaluator.num_taskings.times do
        task.taskings << FactoryGirl.build(:tasking, task: task)
      end
    end
  end
end
