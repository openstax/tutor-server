FactoryBot.define do
  factory :tasks_tasking, class: '::Tasks::Models::Tasking' do
    association :task, factory: :tasks_task

    after(:build) do |tasking|
      tasking.role ||= build(:course_membership_student).role
      tasking.period ||= tasking.role.student&.period
    end
  end
end
