FactoryGirl.define do
  factory :tasks_tasking, class: '::Tasks::Models::Tasking' do
    role { Entity::Models::Role.create! }
    task { Entity::Models::Task.create! }
    # association :role, factory: :entity_role
    # association :task, factory: :entity_task
  end
end
