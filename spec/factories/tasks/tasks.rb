FactoryGirl.define do
  factory :tasks_task, class: '::Tasks::Models::Task' do
    transient do
      duration 1.week
      step_types []
      tasked_to []
      ecosystem { FactoryGirl.build(:content_ecosystem) }
      num_random_taskings 0
    end

    association :task_plan, factory: :tasks_task_plan
    association :entity_task, factory: :entity_task
    task_type :reading
    title       { task_plan.title }
    description { task_plan.description }
    opens_at { Time.now }
    due_at { (opens_at || Time.now) + duration }
    after(:build) do |task, evaluator|
      AddSpyInfo[to: task, from: evaluator.ecosystem]

      evaluator.step_types.each_with_index do |type, i|
        tasked = FactoryGirl.build(type, skip_task: true)
        task.task_steps << tasked.task_step
      end

      evaluator.num_random_taskings.times do
        task.entity_task.taskings << FactoryGirl.build(:tasks_tasking, task: task.entity_task)
      end

      [evaluator.tasked_to].flatten.each do |role|
        task.entity_task.taskings << FactoryGirl.build(:tasks_tasking, task: task.entity_task,
                                                                       role: role)
      end
    end
  end
end
