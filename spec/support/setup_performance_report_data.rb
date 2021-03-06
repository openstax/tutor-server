class SetupPerformanceReportData
  lev_routine

  protected

  def exec(course:, teacher:, students: [], teacher_students: [], ecosystem:)
    students = [students].flatten

    # There should be at least 4 students
    (4 - students.length).times { students << FactoryBot.create(:user_profile) }

    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
    AddUserAsCourseTeacher[course: course, user: teacher] \
      unless CourseMembership::IsCourseTeacher[course: course, roles: teacher.roles]
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

    # Exclude introduction pages
    pages = ecosystem.books.first.as_toc.pages.reject { |page| page.title == 'Introduction' }

    teacher_students.each do |teacher_student|
      roles << CreateOrResetTeacherStudent[user: teacher_student, period: period_1]
    end

    student_tasks = setup_tasks(course, ecosystem, roles, pages)

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

    page_ids = pages.map(&:id).map(&:to_s)
    exercise_ids = Content::Models::Page.where(
      id: page_ids
    ).pluck(:homework_core_exercise_ids).flatten
    exercises = Content::Models::Exercise.where(id: exercise_ids)

    time_zone = course.time_zone

    reading_taskplan = FactoryBot.build(
      :tasks_task_plan,
      title: 'Reading task plan',
      course: course,
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
      opens_at: time_zone.now - 1.week,
      due_at: time_zone.now.yesterday,
      closes_at: time_zone.now + 6.days
    )

    reading_taskplan.save!

    DistributeTasks[task_plan: reading_taskplan]

    homework_taskplan = FactoryBot.build(
      :tasks_task_plan,
      title: 'Homework task plan',
      course: course,
      type: 'homework',
      assistant: homework_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: {
        exercises: exercises.first(5).map do |exercise|
          { id: exercise.id.to_s, points: [ 1.0 ] * exercise.number_of_questions }
        end,
        exercises_count_dynamic: 2
      },
      num_tasking_plans: 0
    )

    homework_taskplan.tasking_plans << FactoryBot.build(
      :tasks_tasking_plan,
      target: course,
      task_plan: homework_taskplan,
      opens_at: time_zone.now.yesterday - 2.days,
      due_at: time_zone.now.yesterday - 1.day,
      closes_at: time_zone.now + 5.days
    )

    homework_taskplan.save!

    DistributeTasks[task_plan: homework_taskplan]

    homework2_taskplan = FactoryBot.build(
      :tasks_task_plan,
      title: 'Homework 2 task plan',
      course: course,
      type: 'homework',
      assistant: homework_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: {
        exercises: exercises.last(2).map do |exercise|
          { id: exercise.id.to_s, points: [ 1.0 ] * exercise.number_of_questions }
        end,
        exercises_count_dynamic: 2
      },
      num_tasking_plans: 0
    )

    homework2_taskplan.tasking_plans << FactoryBot.build(
      :tasks_tasking_plan,
      target: course,
      task_plan: homework2_taskplan,
      opens_at: time_zone.now - 2.weeks,
      due_at: time_zone.now,
      closes_at: time_zone.now + 1.week
    )

    homework2_taskplan.save!

    DistributeTasks[task_plan: homework2_taskplan]

    future_homework_taskplan = FactoryBot.build(
      :tasks_task_plan,
      title: 'Future Homework task plan',
      course: course,
      type: 'homework',
      assistant: homework_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: {
        exercises: exercises.first(5).map do |exercise|
          { id: exercise.id.to_s, points: [ 1.0 ] * exercise.number_of_questions }
        end,
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
      closes_at: time_zone.now + 2.5.days
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
    is_correct   = ->(task_step, index) { index < task_step.task.task_steps.size - 1 }
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
