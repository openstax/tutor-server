FactoryGirl.define do
  factory :tasks_task, class: '::Tasks::Models::Task' do
    transient do
      duration 1.week
      step_types []
      tasked_to []
      num_random_taskings 0
    end

    task_type :reading

    ecosystem   { FactoryGirl.create(:content_ecosystem) }
    task_plan   { build :tasks_task_plan, ecosystem: ecosystem }
    title       { task_plan.title }
    description { task_plan.description }
    time_zone   { task_plan.owner.time_zone }
    opens_at    { time_zone.to_tz.now }
    due_at      { (opens_at || time_zone.to_tz.now) + duration }

    after(:build) do |task, evaluator|
      AddSpyInfo[to: task, from: task.ecosystem]

      evaluator.step_types.each_with_index do |type, i|
        tasked = FactoryGirl.build(type, skip_task: true)
        task.add_step(tasked.task_step)
      end

      evaluator.num_random_taskings.times do
        task.taskings << FactoryGirl.build(:tasks_tasking, task: task)
      end

      [evaluator.tasked_to].flatten.each do |role|
        task.taskings << FactoryGirl.build(:tasks_tasking, task: task, role: role)
      end
    end
  end
end
