# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :assigned_task do
    assignee_type "MyString"
    assignee_id 1
    user_id 1
    task_id 1
  end
end
