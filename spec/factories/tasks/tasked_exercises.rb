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
      tasked_to { build(:user) }
      skip_task false
    end

    association :exercise, factory: :content_exercise
    url { exercise.url }
    title { exercise.title }
    question_id { exercise.content_as_independent_questions.first[:id] }

    after(:build) do |tasked_exercise, evaluator|
      options = { tasked: tasked_exercise }
      options[:task] = nil if evaluator.skip_task

      tasked_exercise.task_step ||= build(:tasks_task_step, options)
    end

    trait :with_tasking do
      after(:build) do |tasked, evaluator|
        create(:tasks_tasking, role: evaluator.tasked_to, task: tasked.task_step.task)
      end
    end

  end
end
