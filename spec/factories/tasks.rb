# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :task do
    taskable nil
    user_id 1
    task_plan_id 1
    opens_at "2014-09-26 14:32:12"
    due_at "2014-09-26 14:32:12"
    is_shared false
    details nil
  end
end
