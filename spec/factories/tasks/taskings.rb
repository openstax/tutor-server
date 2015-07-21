FactoryGirl.define do
  factory :tasks_tasking, class: '::Tasks::Models::Tasking' do
    role   { Entity::Role.create! }
    task   { Entity::Task.create! }
    period { role.student.try(:period) }
  end
end
