FactoryGirl.define do
  factory :tasks_task_page_cache, class: 'Tasks::Models::TaskPageCache' do
    association :task,    factory: :tasks_task
    association :student, factory: :course_membership_student
    association :page,    factory: :content_page

    num_assigned_exercises  0
    num_completed_exercises 0
    num_correct_exercises   0
  end
end
