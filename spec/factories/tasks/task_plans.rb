require_relative '../../mocks/assistants/dummy_assistant'

FactoryBot.define do
  factory :tasks_task_plan, class: '::Tasks::Models::TaskPlan' do
    transient do
      duration                  { 1.week }
      num_tasking_plans         { 1 }
      assistant_code_class_name { 'DummyAssistant' }
      published_at              { nil }
      target                    { nil }
      opens_at                  { nil }
      due_at                    { nil }
    end

    title                       { 'A task' }
    settings                    { {} }
    type                        do
      grading_template.nil? ? 'reading' : grading_template.task_plan_type
    end
    first_published_at          { published_at }
    last_published_at           { published_at }

    after(:build) do |task_plan, evaluator|
      code_class_name_hash = { code_class_name: evaluator.assistant_code_class_name }
      task_plan.assistant ||= Tasks::Models::Assistant.find_by(code_class_name_hash) ||
                              build(:tasks_assistant, code_class_name_hash)

      task_plan.course ||= evaluator.target.try(:course) || build(:course_profile_course)
      task_plan.ecosystem ||= task_plan.course.ecosystem
      AddEcosystemToCourse.call(ecosystem: task_plan.ecosystem, course: task_plan.course) \
        unless task_plan.ecosystem.nil? || task_plan.course.ecosystem == task_plan.ecosystem
      task_plan.grading_template ||= task_plan.owner.grading_templates.detect do |grading_template|
        grading_template.task_plan_type.to_s == task_plan.type
      end
      task_plan.grading_template ||= build(
        :tasks_grading_template, course: task_plan.course, task_plan_type: task_plan.type.to_sym
      ) if [ 'reading', 'homework' ].include? task_plan.type

      now = task_plan.time_zone.now
      task_plan.tasking_plans += evaluator.num_tasking_plans.times.map do
        args = {
          task_plan: task_plan,
          opens_at: evaluator.opens_at || now,
          due_at: evaluator.due_at || now + evaluator.duration,
          closes_at: evaluator.closes_at || task_plan.course.ends_at - 1.day
        }
        args[:target] = evaluator.target unless evaluator.target.nil?

        build :tasks_tasking_plan, args
      end
    end
  end
end
