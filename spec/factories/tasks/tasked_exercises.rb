# Examples
#
# 1) Create a tasked exercise:
#      FactoryGirl.create(:tasks_tasked_exercise)
# 2) Create a tasked exercise tasked to a new user:
#      FactoryGirl.create(:tasks_tasked_exercise, :with_tasking)
# 3) Create a tasked exercise tasked to an existing user:
#      FactoryGirl.create(:tasks_tasked_exercise, :with_tasking, tasked_to: a_user)

FactoryGirl.define do
  factory :tasks_tasked_exercise, class: '::Tasks::Models::TaskedExercise' do
    transient do
      tasked_to { FactoryGirl.build(:user) }
      skip_task false
    end

    task_step nil

    after(:build) do |tasked_exercise, evaluator|
      if tasked_exercise.content.nil?
        exercise_hash = OpenStax::Exercises::V1.fake_client.new_exercise_hash
        tasked_exercise.content = exercise_hash.to_json
      end

      options = { tasked: tasked_exercise }
      options[:task] = nil if evaluator.skip_task

      tasked_exercise.task_step ||= FactoryGirl.build(:tasks_task_step, options)
    end

    trait :with_tasking do
      after(:build) do |tasked, evaluator|
        FactoryGirl.create(:tasks_tasking, role: evaluator.tasked_to,
                                           task: tasked.task_step.task.entity_task)
      end
    end

  end
end
