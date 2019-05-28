# Examples
#
# 1) Create a tasked exercise:
#      FactoryBot.create(:tasks_tasked_exercise)
# 2) Create a tasked exercise tasked to a new user:
#      FactoryBot.create(:tasks_tasked_exercise, :with_tasking)
# 3) Create a tasked exercise tasked to an existing user:
#      FactoryBot.create(:tasks_tasked_exercise, :with_tasking, tasked_to: a_user)

FactoryBot.define do
  factory :tasks_tasked_exercise, class: '::Tasks::Models::TaskedExercise' do
    transient do
      tasked_to { build(:entity_role) }
      skip_task { false }
    end

    association :exercise, factory: :content_exercise
    question_id    { exercise.content_as_independent_questions.first[:id] }
    question_index { 0 }
    content        { exercise.content }
    url            { exercise.url }
    title          { exercise.title }

    after(:build) do |tasked_exercise, evaluator|
      options = { tasked: tasked_exercise, skip_task: evaluator.skip_task }

      tasked_exercise.task_step ||= build(:tasks_task_step, options)
    end

    trait :with_tasking do
      after(:build) do |tasked, evaluator|
        # Remove the tasked from the task before validation due to creating the tasking
        # Because saving the tasked_exercise again without a free_response is not valid
        task = tasked.task_step.task
        task_steps = task.task_steps
        task.task_steps = task_steps - [tasked.task_step]
        create(:tasks_tasking, role: evaluator.tasked_to, task: task)
        task.task_steps = task_steps
      end
    end

  end
end
