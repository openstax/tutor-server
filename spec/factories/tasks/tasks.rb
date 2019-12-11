FactoryBot.define do
  factory :tasks_task, class: '::Tasks::Models::Task' do
    transient do
      duration            { 1.week }
      step_types          { [] }
      tasked_to           { [] }
      num_random_taskings { 0 }
      current_time        { Time.current }
    end

    task_type { :reading }

    ecosystem { FactoryBot.create :content_ecosystem }

    after(:build) do |task, evaluator|
      tasked_to = [ evaluator.tasked_to ].flatten

      task.task_plan ||= build(
        :tasks_task_plan,
        ecosystem: task.ecosystem,
        target: tasked_to.first&.course_member.try(:period),
        published_at: evaluator.current_time
      )
      task.title ||= task.task_plan.title
      task.description ||= task.task_plan.description
      owner = task.task_plan.owner
      task.time_zone ||= owner.time_zone unless owner.nil?
      task.opens_at ||= task.time_zone&.to_tz&.now || evaluator.current_time
      task.due_at ||= task.opens_at + evaluator.duration
      task.closes_at ||= owner.ends_at - 1.day unless owner.nil?

      AddSpyInfo[to: task, from: task.ecosystem]

      evaluator.step_types.each_with_index do |type, i|
        tasked = FactoryBot.build type, skip_task: true
        task.task_steps << tasked.task_step
      end

      evaluator.num_random_taskings.times do
        task.taskings << FactoryBot.build(:tasks_tasking, task: task)
      end

      tasked_to.each do |role|
        task.taskings << FactoryBot.build(:tasks_tasking, task: task, role: role)
      end
    end
  end
end
