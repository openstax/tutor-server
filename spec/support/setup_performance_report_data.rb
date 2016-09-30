class SetupPerformanceReportData

  lev_routine

  protected

  def exec(course:, teacher:, students: [], ecosystem:)
    students = [students].flatten

    # There should be at least 4 students
    (students.length + 1..4).each do |extra_student|
      students << FactoryGirl.create(:user)
    end

    CourseContent::AddEcosystemToCourse.call(course: course, ecosystem: ecosystem)
    AddUserAsCourseTeacher[course: course, user: teacher]
    period_1 = course.periods.any? ? course.periods.first :
                                     FactoryGirl.create(:course_membership_period, course: course)
    period_2 = FactoryGirl.create(:course_membership_period, course: course)
    # Add first 2 students to period 1
    students[0..1].each_with_index do |student, index|
      AddUserAsPeriodStudent[period: period_1, user: student, student_identifier: "S#{index + 1}"]
    end
    # Add the rest of the students to period 2
    students[2..-1].each_with_index do |student, index|
      AddUserAsPeriodStudent[period: period_2, user: student, student_identifier: "S#{index + 3}"]
    end

    roles = students.map{ |student| GetUserCourseRoles[course: course, user: student].first }

    # Exclude introduction pages b/c they don't have LOs
    pages = ecosystem.books.first.chapters.flat_map do |ch|
      ch.pages.reject{ |page| page.title == "Introduction" }
    end

    student_tasks = course.is_concept_coach ? setup_cc_tasks(roles, pages) :
                                              setup_tp_tasks(course, ecosystem, roles, pages)

    course.is_concept_coach ? answer_cc_tasks(student_tasks) : answer_tp_tasks(student_tasks)
  end

  def setup_cc_tasks(roles, pages)
    exercises = [pages.first.exercises.first(6), pages.last.exercises.last(3)]

    roles.map do |role|
      exercises.map do |exercises|
        page = exercises.first.page

        group_types = (exercises.size - 1).times.map{ :core_group } + [:spaced_practice_group]

        related_content_array = exercises.map{ page.related_content }

        Tasks::CreateConceptCoachTask[
          role: role, page: page, exercises: exercises,
          group_types: group_types, related_content_array: related_content_array
        ]
      end
    end
  end

  def get_assistant(course:, task_plan_type:)
    course.course_assistants.where{tasks_task_plan_type == task_plan_type}.first.assistant
  end

  def get_student_tasks(role)
    task_types = Tasks::Models::Task.task_types.values_at(:reading, :homework, :concept_coach)

    Tasks::Models::Task
      .joins { taskings }
      .where { taskings.entity_role_id == my { role.id } }
      .where { task_type.in task_types }
      .order { due_at_ntz }
      .preload { task_steps.tasked }
      .to_a.select(&:past_open?)
  end

  def setup_tp_tasks(course, ecosystem, roles, pages)
    reading_assistant = get_assistant(course: course, task_plan_type: 'reading')
    homework_assistant = get_assistant(course: course, task_plan_type: 'homework')

    page_ids = pages.map{ |page| page.id.to_s }
    exercise_ids = pages.flat_map{ |page| page.exercises.map{ |ex| ex.id.to_s } }

    time_zone = course.time_zone.to_tz

    reading_taskplan = Tasks::Models::TaskPlan.new(
      title: 'Reading task plan',
      owner: course,
      type: 'reading',
      assistant: reading_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: { page_ids: page_ids.first(2).map(&:to_s) }
    )

    reading_taskplan.tasking_plans << Tasks::Models::TaskingPlan.new(
      target: course, task_plan: reading_taskplan,
      opens_at: time_zone.now, due_at: time_zone.now + 1.week,
      time_zone: course.time_zone
    )

    reading_taskplan.save!

    DistributeTasks[task_plan: reading_taskplan]

    homework_taskplan = Tasks::Models::TaskPlan.new(
      title: 'Homework task plan',
      owner: course,
      type: 'homework',
      assistant: homework_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: {
        exercise_ids: exercise_ids.first(5),
        exercises_count_dynamic: 2
      }
    )

    homework_taskplan.tasking_plans << Tasks::Models::TaskingPlan.new(
      target: course, task_plan: homework_taskplan,
      opens_at: time_zone.now, due_at: time_zone.now.tomorrow,
      time_zone: course.time_zone
    )

    homework_taskplan.save!

    DistributeTasks[task_plan: homework_taskplan]

    homework2_taskplan = Tasks::Models::TaskPlan.new(
      title: 'Homework 2 task plan',
      owner: course,
      type: 'homework',
      assistant: homework_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: {
        exercise_ids: exercise_ids.last(2),
        exercises_count_dynamic: 2
      }
    )

    homework2_taskplan.tasking_plans << Tasks::Models::TaskingPlan.new(
      target: course, task_plan: homework2_taskplan,
      opens_at: time_zone.now, due_at: time_zone.now + 2.weeks,
      time_zone: course.time_zone
    )

    homework2_taskplan.save!

    DistributeTasks[task_plan: homework2_taskplan]

    future_homework_taskplan = Tasks::Models::TaskPlan.new(
      title: 'Future Homework task plan',
      owner: course,
      type: 'homework',
      assistant: homework_assistant,
      content_ecosystem_id: ecosystem.id,
      settings: {
        exercise_ids: exercise_ids.first(5),
        exercises_count_dynamic: 2
      }
    )

    future_homework_taskplan.tasking_plans << Tasks::Models::TaskingPlan.new(
      target: course,
      task_plan: future_homework_taskplan,
      opens_at: time_zone.now + 1.5.days,
      due_at: time_zone.now + 2.days,
      time_zone: course.time_zone
    )

    future_homework_taskplan.save!

    DistributeTasks[task_plan: future_homework_taskplan]

    roles.map{ |role| get_student_tasks(role) }
  end

  def answer_cc_tasks(student_tasks)
    # User 1 answered everything in first CC correctly
    student_1_tasks = student_tasks[0]
    student_1_tasks[0].core_task_steps.each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: true]
    end
    student_1_tasks[0].reload.non_core_task_steps.each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: true]
    end

    # User 1 answered 3 correct, 1 incorrect in 2nd CC
    student_1_tasks[1].core_task_steps.each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: true]
    end
    student_1_tasks[1].reload
    Preview::AnswerExercise[
      task_step: student_1_tasks[1].non_core_task_steps.first, is_correct: true
    ]
    Preview::AnswerExercise[
      task_step: student_1_tasks[1].non_core_task_steps.last, is_correct: false
    ]

    # User 2 answered 2 questions correctly and 2 incorrectly in first CC
    student_2_tasks = student_tasks[1]
    core_task_steps = student_2_tasks[0].core_task_steps
    core_task_steps.first(2).each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: true]
    end
    core_task_steps.last(2).each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: false]
    end

    # User 2 answered 1 correct in 2nd CC
    Preview::AnswerExercise[task_step: student_2_tasks[1].core_task_steps.first, is_correct: true]

    # User 3 answered everything in first CC correctly
    student_3_tasks = student_tasks[2]
    student_3_tasks[0].core_task_steps.each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: true]
    end
    student_3_tasks[0].reload.non_core_task_steps.each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: true]
    end
  end

  def answer_tp_tasks(student_tasks)
    # User 1 answered everything in homework correctly
    student_1_tasks = student_tasks[0]
    student_1_tasks[0].core_task_steps.each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: true]
    end
    student_1_tasks[0].reload.non_core_task_steps.each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: true]
    end

    # User 1 completed the reading
    student_1_tasks[1].core_task_steps.each do |ts|
      ts.exercise? ? Preview::AnswerExercise[task_step: ts, is_correct: false] : \
                     MarkTaskStepCompleted[task_step: ts]
    end
    student_1_tasks[1].reload.non_core_task_steps.each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: false]
    end

    # User 1 answered 2 correct, 1 incorrect in 2nd homework
    student_1_tasks[2].core_task_steps.each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: true]
    end
    student_1_tasks[2].reload
    raise 'A personalized step was unexpectedly removed from homework ' +
          '(probably because Biglearn returned no PEs)' \
      if student_1_tasks[2].non_core_task_steps.empty?
    Preview::AnswerExercise[
      task_step: student_1_tasks[2].non_core_task_steps.first, is_correct: false
    ]

    # User 2 answered 2 questions correctly and 2 incorrectly in homework
    student_2_tasks = student_tasks[1]
    core_task_steps = student_2_tasks[0].core_task_steps
    core_task_steps.first(2).each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: true]
    end
    core_task_steps.last(2).each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: false]
    end

    # User 2 started the reading
    MarkTaskStepCompleted[task_step: student_2_tasks[1].task_steps.first]

    # User 2 answered 1 correct in 2nd homework
    Preview::AnswerExercise[task_step: student_2_tasks[2].core_task_steps.first,
                          is_correct: true]

    # User 3 answered everything in homework correctly
    student_3_tasks = student_tasks[2]
    student_3_tasks[0].core_task_steps.each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: true]
    end
    student_3_tasks[0].reload.non_core_task_steps.each do |ts|
      Preview::AnswerExercise[task_step: ts, is_correct: true]
    end
  end

end
