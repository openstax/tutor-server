FactoryBot.define do
  factory :tasks_task, class: '::Tasks::Models::Task' do
    transient do
      duration            { 1.week }
      step_types          { [] }
      tasked_to           { [] }
      num_random_taskings { 0 }
    end

    task_type { :reading }

    after(:build) do |task, evaluator|
      tasked_to = [ evaluator.tasked_to ].flatten

      period = tasked_to.first&.course_member&.period

      task.course ||= period&.course || FactoryBot.build(:course_profile_course)
      task.ecosystem ||= task.course.ecosystem
      AddEcosystemToCourse.call(ecosystem: task.ecosystem, course: task.course) \
        unless task.ecosystem.nil? || task.course.ecosystem == task.ecosystem

      now ||= task.time_zone.now
      task.task_plan ||= create(
        :tasks_task_plan,
        course: task.course,
        ecosystem: task.ecosystem,
        target: period,
        published_at: now
      )
      task.title ||= task.task_plan.title
      task.description ||= task.task_plan.description
      task.opens_at ||= now
      task.due_at ||= task.opens_at + evaluator.duration
      task.closes_at ||= task.course.ends_at - 1.day unless task.course.nil?

      task.ecosystem.save! if task.ecosystem.new_record?
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
