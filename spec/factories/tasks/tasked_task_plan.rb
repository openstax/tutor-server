FactoryBot.define do
  factory :tasked_task_plan, parent: :tasks_task_plan do
    type { :reading }

    assistant do
      assist = type == :reading ? 'IReadingAssistant' : 'HomeworkAssistant'
      Tasks::Models::Assistant.find_by(
        code_class_name: "Tasks::Assistants::#{assist}"
      ) || FactoryBot.create(
        :tasks_assistant, code_class_name: "Tasks::Assistants::#{assist}"
      )
    end

    transient do
      number_of_students { 10 }
    end

    transient do
      number_of_exercises_per_page { 5 }
    end

    association :ecosystem, factory: :mini_ecosystem

    course { FactoryBot.build :course_profile_course, offering: nil }

    settings {
      s = { page_ids: ecosystem.pages.sort_by(&:book_indices).first(4).map { |pg| pg.id.to_s } }
      if type == :homework
        s.merge!(
          exercises: s[:page_ids].flat_map do |pg_id|
            ecosystem.pages.find(pg_id).exercises.sample(number_of_exercises_per_page)
          end.map { |ex| { id: ex.id.to_s, points: [1.0]*ex.number_of_questions } },
          exercises_count_dynamic: 3
        )
      end
      s
    }

    after(:build) do |task_plan, evaluator|
      course = task_plan.course
      period = course.periods.first || FactoryBot.create(
        :course_membership_period, course: course
      )

      evaluator.number_of_students.times do
        AddUserAsPeriodStudent.call(user: create(:user_profile), period: period)
      end

      task_plan.tasking_plans = [build(:tasks_tasking_plan, task_plan: task_plan, target: period)]
    end

    after(:create) { |task_plan, evaluator| DistributeTasks.call(task_plan: task_plan) }
  end
end
