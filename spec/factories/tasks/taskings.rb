FactoryBot.define do
  factory :tasks_tasking, class: '::Tasks::Models::Tasking' do
    association :task, factory: :tasks_task

    after(:build) do |tasking|
      tasking.role ||= build(:course_membership_student).role
    end
  end
end
