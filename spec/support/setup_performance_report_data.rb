class SetupPerformanceReportData
  lev_routine

  protected
  def exec(course:, teacher:, students: [], book:)
    students = [students].flatten
    reading_assistant = FactoryGirl.create(:tasks_assistant,
      code_class_name: 'Tasks::Assistants::IReadingAssistant')
    homework_assistant = FactoryGirl.create :tasks_assistant,
      code_class_name: 'Tasks::Assistants::HomeworkAssistant'

    if students.none?
      students = [FactoryGirl.create(:user_profile),
                  FactoryGirl.create(:user_profile)]
    elsif students.one?
      students << FactoryGirl.create(:user_profile)
    end

    CourseContent::AddBookToCourse.call(course: course, book: book)
    AddUserAsCourseTeacher[course: course, user: teacher.entity_user]
    period = course.periods.empty? ? CreatePeriod[course: course] : course.periods.first
    students.each do |student|
      AddUserAsPeriodStudent[period: period, user: student.entity_user]
    end

    page_ids = Content::Models::Page.all.map(&:id)

    reading_taskplan = Tasks::Models::TaskPlan.create!(
      title: 'Reading task plan',
      owner: course,
      type: 'reading',
      assistant: reading_assistant,
      settings: { page_ids: page_ids.first(2).collect(&:to_s) }
    )

    reading_taskplan.tasking_plans << Tasks::Models::TaskingPlan
      .create!(target: course, task_plan: reading_taskplan,
               opens_at: Time.now, due_at: Time.now + 1.week)

    DistributeTasks[reading_taskplan]

    homework_taskplan = Tasks::Models::TaskPlan.create!(
      title: 'Homework task plan',
      owner: course,
      type: 'homework',
      assistant: homework_assistant,
      settings: {
        exercise_ids: Content::Models::Exercise.first(5).collect(&:id).map(&:to_s),
        exercises_count_dynamic: 2
      }
    )

    homework_taskplan.tasking_plans << Tasks::Models::TaskingPlan
      .create!(target: course, task_plan: homework_taskplan,
               opens_at: Time.now, due_at: Time.now + 1.day)

    DistributeTasks[homework_taskplan]

    homework2_taskplan = Tasks::Models::TaskPlan.create!(
      title: 'Homework 2 task plan',
      owner: course,
      type: 'homework',
      assistant: homework_assistant,
      settings: {
        exercise_ids: Content::Models::Exercise.last(2).collect(&:id).map(&:to_s),
        exercises_count_dynamic: 2
      }
    )

    homework2_taskplan.tasking_plans << Tasks::Models::TaskingPlan
      .create!(target: course, task_plan: homework2_taskplan,
               opens_at: Time.now, due_at: Time.now + 2.week)

    DistributeTasks[homework2_taskplan]

    student_1_role = GetUserCourseRoles[course: course,
                                        user: students[0].entity_user].first
    student_2_role = GetUserCourseRoles[course: course,
                                        user: students[1].entity_user].first
    task_types = Tasks::Models::Task.task_types.values_at(:reading, :homework)

    student_1_tasks = Tasks::Models::Task
      .joins { taskings }
      .where { taskings.entity_role_id == my { student_1_role.id } }
      .where { task_type.in my { task_types } }
      .order { due_at }
      .includes { task_steps.tasked }

    student_2_tasks = Tasks::Models::Task
      .joins { taskings }
      .where { taskings.entity_role_id == my { student_2_role.id } }
      .where { task_type.in my { task_types } }
      .order { due_at }
      .includes { task_steps.tasked }

    # User 1 answered everything in homework task plan correctly
    student_1_tasks[0].core_task_steps.each do |ts|
      Hacks::AnswerExercise[task_step: ts, is_correct: true]
    end
    student_1_tasks[0].non_core_task_steps.each do |ts|
      Hacks::AnswerExercise[task_step: ts, is_correct: true]
    end

    # User 1 completed the reading task plan
    student_1_tasks[1].core_task_steps.each do |ts|
      MarkTaskStepCompleted[task_step: ts]
    end
    student_1_tasks[1].non_core_task_steps.each do |ts|
      MarkTaskStepCompleted[task_step: ts]
    end

    # User 1 answered 3 correct, 1 incorrect in 2nd homework
    student_1_tasks[2].core_task_steps.each do |ts|
      Hacks::AnswerExercise[task_step: ts, is_correct: true]
    end
    Hacks::AnswerExercise[task_step: student_1_tasks[2].non_core_task_steps.first,
                          is_correct: true]

    # User 2 answered 2 questions correctly and 2 incorrectly in
    # homework task plan
    core_task_steps = student_2_tasks[0].core_task_steps
    raise "expected at least 4 core task steps" if core_task_steps.count < 4
    core_task_steps.first(2).each do |ts|
      Hacks::AnswerExercise[task_step: ts, is_correct: true]
    end

    # User 2 started the reading task plan
    MarkTaskStepCompleted[task_step: student_2_tasks[1].task_steps.first]

    # User 2 answered 1 correct in 2nd homework
    Hacks::AnswerExercise[task_step: student_2_tasks[2].core_task_steps.first,
                          is_correct: true]
  end
end
