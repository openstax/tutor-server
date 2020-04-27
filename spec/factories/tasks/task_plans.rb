require_relative '../../mocks/assistants/dummy_assistant'

FactoryBot.define do
  factory :tasks_task_plan, class: '::Tasks::Models::TaskPlan' do
    transient do
      duration                  { 1.week }
      time_zone                 { owner.try(:time_zone)&.to_tz || Time.zone }
      opens_at                  { time_zone.now }
      due_at                    { opens_at + duration }
      num_tasking_plans         { 1 }
      assistant_code_class_name { 'DummyAssistant' }
      published_at              { nil }
      target                    { nil }
    end

    title                 { 'A task' }
    settings              { {} }
    type                  { 'reading' }
    is_feedback_immediate { type != 'homework' }
    first_published_at    { published_at }
    last_published_at     { published_at }

    after(:build) do |task_plan, evaluator|
      code_class_name_hash = { code_class_name: evaluator.assistant_code_class_name }
      task_plan.assistant ||= Tasks::Models::Assistant.find_by(code_class_name_hash) ||
                              build(:tasks_assistant, code_class_name_hash)

      task_plan.owner ||= evaluator.target.try(:course) ||
                          build(:course_profile_course).tap do |course|
        AddEcosystemToCourse.call(ecosystem: task_plan.ecosystem, course: course) \
          unless task_plan.ecosystem.nil? || course.ecosystem == task_plan.ecosystem
      end
      task_plan.ecosystem ||= task_plan.owner.ecosystem

      task_plan.tasking_plans += evaluator.num_tasking_plans.times.map do
        args = {
          task_plan: task_plan,
          opens_at: evaluator.opens_at,
          due_at: evaluator.due_at,
          time_zone: task_plan.owner.try(:time_zone)
        }
        args[:target] = evaluator.target unless evaluator.target.nil?

        build :tasks_tasking_plan, args
      end
    end
  end
end
