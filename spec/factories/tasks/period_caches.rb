FactoryBot.define do
  factory :tasks_period_cache, class: 'Tasks::Models::PeriodCache' do
    association    :period,    factory: :course_membership_period
    association    :ecosystem, factory: :content_ecosystem
    association    :task_plan, factory: :tasks_task_plan
    student_ids    { period.students.map(&:id) }
    as_toc         { { books: [] } }
  end
end
