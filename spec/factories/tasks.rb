FactoryGirl.define do
  factory :task do
    transient do
      duration 1.week
      step_types []
      tasked_to []
      num_random_taskings 0
    end

    task_plan
    task_type "reading"
    title "A task"
    opens_at { Time.now }
    due_at { opens_at + duration }

    after(:build) do |task, evaluator|
      evaluator.step_types.each_with_index do |type, i|
        tasked = FactoryGirl.build(type, skip_task: true)
        task.task_steps << tasked.task_step
      end

      evaluator.num_random_taskings.times do
        task.taskings << FactoryGirl.build(:tasking, task: task)
      end

      [evaluator.tasked_to].flatten.each do |taskee|
        task.taskings << FactoryGirl.build(:tasking, task: task, taskee: taskee)
      end
    end
  end
end
