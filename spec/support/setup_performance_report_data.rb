class SetupPerformanceReportData
  lev_routine

  protected

  def exec(course:, teacher:, students: [], teacher_students: [], ecosystem:)
    students = [students].flatten

    # There should be at least 4 students
    (4 - students.length).times { students << FactoryBot.create(:user) }

    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
    AddUserAsCourseTeacher[course: course, user: teacher] \
      unless CourseMembership::IsCourseTeacher[course: course, roles: teacher.to_model.roles]
    period_1 = course.periods.any? ? course.periods.first :
                                     FactoryBot.create(:course_membership_period, course: course)
    period_2 = FactoryBot.create(:course_membership_period, course: course)
    # Add first 2 students to period 1
    students[0..1].each_with_index do |student, index|
      AddUserAsPeriodStudent[period: period_1, user: student, student_identifier: "S#{index + 1}"]
    end
    # Add the rest of the students to period 2
    students[2..-1].each_with_index do |student, index|
      AddUserAsPeriodStudent[period: period_2, user: student, student_identifier: "S#{index + 3}"]
    end

    roles = students.map { |student| GetUserCourseRoles[courses: course, user: student].first }

    # Exclude introduction pages b/c they don't have LOs
    pages = ecosystem.books.first.chapters.flat_map do |ch|
      ch.pages.reject { |page| page.title == "Introduction" }
    end

    teacher_students.each do |teacher_student|
      roles << CreateOrResetTeacherStudent[user: teacher_student, period: period_1]
    end

    student_tasks = course.is_concept_coach ? setup_cc_tasks(roles, pages) :
                                              setup_tasks(course, ecosystem, roles, pages)

    answer_tasks(student_tasks)
  end


  def get_assistant(course:, task_plan_type:)
    course.course_assistants.find_by(tasks_task_plan_type: task_plan_type).assistant
  end

  def get_student_tasks(role)
    task_types = Tasks::Models::Task.task_types.values_at(:reading, :homework, :concept_coach)

    Tasks::Models::Task
      .joins(:taskings)
      .where(taskings: { entity_role_id: role.id })
      .where(task_type: task_types)
      .order(:due_at_ntz)
      .preload(task_steps: :tasked)
      .filter(&:past_open?)
  end

  def setup_tasks(course, ecosystem, roles, pages)
    reading_assistant = get_assistant(course: course, task_plan_type: 'reading')
    homework_assistant = get_assistant(course: course, task_plan_type: 'homework')

    page_ids = pages.map { |page| page.id.to_s }
    exercise_ids = pages.flat_map { |page| page.exercises.map { |ex| ex.id.to_s } }

    time_zone = course.time_zone.to_tz

    reading_taskplan = FactoryBot.build(
      :tasks_task_plan,
      title: 'Reading task plan',
      owner: course,
      type: 'reading',
      assistant: reading_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: { page_ids: page_ids.first(2).map(&:to_s) },
      num_tasking_plans: 0
    )

    reading_taskplan.tasking_plans << FactoryBot.build(
      :tasks_tasking_plan,
      target: course,
      task_plan: reading_taskplan,
      opens_at: time_zone.now,
      due_at: time_zone.now + 1.week,
      closes_at: time_zone.now + 2.weeks,
      time_zone: course.time_zone
    )

    reading_taskplan.save!

    DistributeTasks[task_plan: reading_taskplan]

    homework_taskplan = FactoryBot.build(
      :tasks_task_plan,
      title: 'Homework task plan',
      owner: course,
      type: 'homework',
      assistant: homework_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: {
        exercise_ids: exercise_ids.first(5),
        exercises_count_dynamic: 2
      },
      num_tasking_plans: 0
    )

    homework_taskplan.tasking_plans << FactoryBot.build(
      :tasks_tasking_plan,
      target: course, task_plan: homework_taskplan,
      opens_at: time_zone.now,
      due_at: time_zone.now.tomorrow,
      closes_at: time_zone.now.tomorrow + 1.day,
      time_zone: course.time_zone
    )

    homework_taskplan.save!

    DistributeTasks[task_plan: homework_taskplan]

    homework2_taskplan = FactoryBot.build(
      :tasks_task_plan,
      title: 'Homework 2 task plan',
      owner: course,
      type: 'homework',
      assistant: homework_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: {
        exercise_ids: exercise_ids.last(2),
        exercises_count_dynamic: 2
      },
      num_tasking_plans: 0
    )

    homework2_taskplan.tasking_plans << FactoryBot.build(
      :tasks_tasking_plan,
      target: course, task_plan: homework2_taskplan,
      opens_at: time_zone.now,
      due_at: time_zone.now + 2.weeks,
      closes_at: time_zone.now + 4.weeks,
      time_zone: course.time_zone
    )

    homework2_taskplan.save!

    DistributeTasks[task_plan: homework2_taskplan]

    future_homework_taskplan = FactoryBot.build(
      :tasks_task_plan,
      title: 'Future Homework task plan',
      owner: course,
      type: 'homework',
      assistant: homework_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: {
        exercise_ids: exercise_ids.first(5),
        exercises_count_dynamic: 2
      },
      num_tasking_plans: 0
    )

    future_homework_taskplan.tasking_plans << FactoryBot.build(
      :tasks_tasking_plan,
      target: course,
      task_plan: future_homework_taskplan,
      opens_at: time_zone.now + 1.5.days,
      due_at: time_zone.now + 2.days,
      closes_at: time_zone.now + 2.5.days,
      time_zone: course.time_zone
    )

    future_homework_taskplan.save!

    DistributeTasks[task_plan: future_homework_taskplan]

    roles.map { |role| get_student_tasks(role) }
  end

  def answer_tasks(student_tasks)
    # User 1 answered everything in homework correctly
    student_1_tasks = student_tasks[0]
    Preview::WorkTask[task: student_1_tasks[0], is_correct: true]

    # User 1 completed the reading
    Preview::WorkTask[task: student_1_tasks[1], is_correct: false]

    # User 1 answered 2 correct core, 1 correct spaced practice
    # and 1 incorrect personalized exercise (in an SPE slot) in 2nd homework
    is_completed = ->(task_step, index) { true }
    is_correct   = ->(task_step, index) { index < task_step.task.task_steps.size }
    Preview::WorkTask[task: student_1_tasks[2], is_completed: is_completed, is_correct: is_correct]

    # User 2 answered 2 questions correctly and 2 incorrectly in homework
    student_2_tasks = student_tasks[1]
    is_completed = ->(task_step, index) { index < 2 || index >= task_step.task.task_steps.size - 2 }
    is_correct   = ->(task_step, index) { index < 2 }
    Preview::WorkTask[task: student_2_tasks[0], is_completed: is_completed, is_correct: is_correct]

    # User 2 started the reading
    MarkTaskStepCompleted[task_step: student_2_tasks[1].task_steps.first]

    # User 2 answered 1 correct in 2nd homework
    Preview::AnswerExercise[task_step: student_2_tasks[2].core_task_steps.first, is_correct: true]

    # User 3 answered everything in homework correctly
    student_3_tasks = student_tasks[2]
    Preview::WorkTask[task: student_3_tasks[0], is_correct: true]
  end
end
