FactoryBot.define do
  factory :tasks_task, class: '::Tasks::Models::Task' do
    transient do
      duration { 1.week }
      step_types { [] }
      tasked_to { [] }
      num_random_taskings { 0 }
      current_time { time_zone.try!(:to_tz).try!(:now) || Time.current }
    end

    task_type { :reading }

    ecosystem   { FactoryBot.create(:content_ecosystem) }
    task_plan   { build :tasks_task_plan, ecosystem: ecosystem }
    title       { task_plan.try!(:title) }
    description { task_plan.try!(:description) }
    time_zone   { task_plan.try!(:owner).try!(:time_zone) }
    opens_at    { current_time }
    due_at      { (opens_at || current_time) + duration }

    after(:build) do |task, evaluator|
      AddSpyInfo[to: task, from: task.ecosystem]

      evaluator.step_types.each_with_index do |type, i|
        tasked = FactoryBot.build(type, skip_task: true)
        task.task_steps << tasked.task_step
      end

      evaluator.num_random_taskings.times do
        task.taskings << FactoryBot.build(:tasks_tasking, task: task)
      end

      [evaluator.tasked_to].flatten.each do |role|
        task.taskings << FactoryBot.build(:tasks_tasking, task: task, role: role)
      end
    end
  end
end
