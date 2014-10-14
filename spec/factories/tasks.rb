# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :task do
    ignore do 
      opens_at_time Time.now
      duration 1.week
    end

    task_plan nil
    opens_at { opens_at_time }
    due_at { opens_at_time + duration }
    is_shared false
    details { |details| details.association(:reading) }
    title "A task"
  end
end
