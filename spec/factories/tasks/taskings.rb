FactoryGirl.define do
  factory :tasks_tasking, class: '::Tasks::Models::Tasking' do
    association :role, factory: :entity_role
    association :task, factory: :tasks_task

    period { role.student.try(:period) }
  end
end
