class SetupPerformanceReportData
  lev_routine

  protected
  def exec(course:, teacher:, students: [], ecosystem:)
    students = [students].flatten
    reading_assistant = get_assistant(course: course, task_plan_type: 'reading')
    homework_assistant = get_assistant(course: course, task_plan_type: 'homework')

    # There should be at least 4 students
    (students.length + 1..4).each do |extra_student|
      students << FactoryGirl.create(:user)
    end

    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
    AddUserAsCourseTeacher.call(course: course, user: teacher)
    period_1 = course.periods.empty? ? CreatePeriod.call(course: course) : course.periods.first
    period_2 = CreatePeriod.call(course: course)
    # Add first 2 students to period 1
    students[0..1].each_with_index do |student, index|
      AddUserAsPeriodStudent.call(period: period_1, user: student, student_identifier: "S#{index + 1}")
    end
    # Add the rest of the students to period 2
    students[2..-1].each_with_index do |student, index|
      AddUserAsPeriodStudent.call(period: period_2, user: student, student_identifier: "S#{index + 3}")
    end

    # Exclude introduction pages b/c they don't have LOs
    page_ids = Content::Models::Page.where{title != "Introduction"}.map(&:id)

    reading_taskplan = Tasks::Models::TaskPlan.new(
      title: 'Reading task plan',
      owner: course,
      type: 'reading',
      assistant: reading_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: { page_ids: page_ids.first(2).collect(&:to_s) }
    )

    reading_taskplan.tasking_plans << Tasks::Models::TaskingPlan.new(
      target: course, task_plan: reading_taskplan, opens_at: Time.now, due_at: Time.now + 1.week
    )

    reading_taskplan.save!

    DistributeTasks[reading_taskplan]

    homework_taskplan = Tasks::Models::TaskPlan.new(
      title: 'Homework task plan',
      owner: course,
      type: 'homework',
      assistant: homework_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: {
        exercise_ids: Content::Models::Exercise.first(5).collect(&:id).map(&:to_s),
        exercises_count_dynamic: 2
      }
    )

    homework_taskplan.tasking_plans << Tasks::Models::TaskingPlan.new(
      target: course, task_plan: homework_taskplan, opens_at: Time.now, due_at: Time.now + 1.day
    )

    homework_taskplan.save!

    DistributeTasks[homework_taskplan]

    homework2_taskplan = Tasks::Models::TaskPlan.new(
      title: 'Homework 2 task plan',
      owner: course,
      type: 'homework',
      assistant: homework_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: {
        exercise_ids: Content::Models::Exercise.last(2).collect(&:id).map(&:to_s),
        exercises_count_dynamic: 2
      }
    )

    homework2_taskplan.tasking_plans << Tasks::Models::TaskingPlan.new(
      target: course, task_plan: homework2_taskplan, opens_at: Time.now, due_at: Time.now + 2.week
    )

    homework2_taskplan.save!

    DistributeTasks[homework2_taskplan]

    future_homework_taskplan = Tasks::Models::TaskPlan.new(
      title: 'Future Homework task plan',
      owner: course,
      type: 'homework',
      assistant: homework_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: {
        exercise_ids: Content::Models::Exercise.first(5).collect(&:id).map(&:to_s),
        exercises_count_dynamic: 2
      }
    )

    future_homework_taskplan.tasking_plans << Tasks::Models::TaskingPlan.new(
      target: course,
      task_plan: future_homework_taskplan,
      opens_at: Time.now + 1.day,
      due_at: Time.now + 2.days
    )

    future_homework_taskplan.save!

    DistributeTasks[future_homework_taskplan]

    student_roles = students.collect do |student|
      GetUserCourseRoles.call(course: course, user: student).first
    end
    student_tasks = student_roles.collect do |student_role|
      get_student_tasks(student_role)
    end

    # User 1 answered everything in homework task plan correctly
    student_1_tasks = student_tasks[0]
    student_1_tasks[0].core_task_steps.each do |ts|
      Hacks::AnswerExercise.call(task_step: ts, is_correct: true)
    end
    student_1_tasks[0].reload.non_core_task_steps.each do |ts|
      Hacks::AnswerExercise.call(task_step: ts, is_correct: true)
    end

    # User 1 completed the reading task plan
    student_1_tasks[1].core_task_steps.each do |ts|
      ts.exercise? ? Hacks::AnswerExercise.call(task_step: ts, is_correct: false) : \
                     MarkTaskStepCompleted.call(task_step: ts)
    end
    student_1_tasks[1].reload.non_core_task_steps.each do |ts|
      Hacks::AnswerExercise.call(task_step: ts, is_correct: false)
    end

    # User 1 answered 3 correct, 1 incorrect in 2nd homework
    student_1_tasks[2].core_task_steps.each do |ts|
      Hacks::AnswerExercise.call(task_step: ts, is_correct: true)
    end
    student_1_tasks[2].reload
    Hacks::AnswerExercise.call(task_step: student_1_tasks[2].non_core_task_steps.first,
                               is_correct: true)
    Hacks::AnswerExercise.call(task_step: student_1_tasks[2].non_core_task_steps.last,
                               is_correct: false)

    # User 2 answered 2 questions correctly and 2 incorrectly in
    # homework task plan
    student_2_tasks = student_tasks[1]
    core_task_steps = student_2_tasks[0].core_task_steps
    raise "expected at least 4 core task steps" if core_task_steps.count < 4
    core_task_steps.first(2).each do |ts|
      Hacks::AnswerExercise.call(task_step: ts, is_correct: true)
    end
    core_task_steps.last(2).each do |ts|
      Hacks::AnswerExercise.call(task_step: ts, is_correct: false)
    end

    # User 2 started the reading task plan
    MarkTaskStepCompleted.call(task_step: student_2_tasks[1].task_steps.first)

    # User 2 answered 1 correct in 2nd homework
    Hacks::AnswerExercise.call(task_step: student_2_tasks[2].core_task_steps.first,
                               is_correct: true)

    # User 3 answered everything in homework task plan correctly
    student_3_tasks = student_tasks[2]
    student_3_tasks[0].core_task_steps.each do |ts|
      Hacks::AnswerExercise.call(task_step: ts, is_correct: true)
    end
    student_3_tasks[0].reload.non_core_task_steps.each do |ts|
      Hacks::AnswerExercise.call(task_step: ts, is_correct: true)
    end
  end

  def get_student_tasks(role)
    task_types = Tasks::Models::Task.task_types.values_at(:reading, :homework)
    Tasks::Models::Task
      .joins { taskings }
      .where { taskings.entity_role_id == my { role.id } }
      .where { task_type.in my { task_types } }
      .where { opens_at <= Time.now }
      .order { due_at }
      .includes { task_steps.tasked }
  end

  def get_assistant(course:, task_plan_type:)
    course.course_assistants.where{tasks_task_plan_type == task_plan_type}.first.assistant
  end
end
