# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :task_plan do
    owner ""
    number ""
    visible_at "2014-09-26 09:52:59"
    opens_at "2014-09-26 09:52:59"
    due_at "2014-09-26 09:52:59"
    is_ready false
    is_shared false
    details { |details| details.association(:reading_plan) }
  end
end
