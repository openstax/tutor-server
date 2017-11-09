FactoryBot.define do
  factory :tasks_concept_coach_task, class: '::Tasks::Models::ConceptCoachTask' do
    association :page, factory: :content_page
    association :role, factory: :entity_role
    association :task, factory: :tasks_task

    after(:build) do |cc_task, evaluator|
      cc_task.task.taskings << Tasks::Models::Tasking.new(role: cc_task.role, task: cc_task.task)
    end
  end
end
