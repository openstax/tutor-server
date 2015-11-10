class GetDashboard
  lev_routine

  uses_routine GetCourseTaskPlans,
               as: :get_plans
  uses_routine ::Tasks::GetTasks,
               as: :get_tasks
  uses_routine GetCourseTeachers,
               as: :get_course_teachers
  uses_routine CourseMembership::IsCourseTeacher
  uses_routine CourseMembership::IsCourseStudent

  protected

  def exec(course:, role:)
    role_type = get_role_type(course, role)

    raise SecurityTransgression if role_type.nil?

    load_role(role, role_type)
    load_course(course, role_type)
    load_tasks(role, role_type)
    if :teacher == role_type
      course.is_concept_coach ? load_cc_stats(course) : load_plans(course)
    end
  end

  def get_role_type(course, role)
    if CourseMembership::IsCourseTeacher[course: course, roles: role]
      :teacher
    elsif CourseMembership::IsCourseStudent[course: course, roles: role]
      :student
    end
  end

  def load_tasks(role, role_type)
    entity_tasks = run(:get_tasks, roles: role).outputs.tasks
    entity_tasks = entity_tasks.joins(:task).preload(:task)
    entity_tasks = entity_tasks.where{ task.opens_at < Time.now } if :student == role_type
    tasks = entity_tasks.map{ |entity_task| entity_task.task }
    outputs[:tasks] = tasks
  end

  def load_plans(course)
    out = run(:get_plans, course: course, include_trouble_flags: true).outputs
    outputs[:plans] = out[:plans].map do |task_plan|
      {
        id: task_plan.id,
        title: task_plan.title,
        type: task_plan.type,
        is_publish_requested: task_plan.is_publish_requested?,
        published_at: task_plan.published_at,
        publish_last_requested_at: task_plan.publish_last_requested_at,
        publish_job_uuid: task_plan.publish_job_uuid,
        tasking_plans: task_plan.tasking_plans,
        is_trouble: out[:trouble_plan_ids].include?(task_plan.id)
      }
    end
  end

  def get_period_performance_maps_from_cc_tasks(cc_tasks)
    all_task_ids = cc_tasks.map{ |cc_task| cc_task.task.task.id }
    completed_tasked_exercises = Tasks::Models::TaskedExercise
      .joins(:task_step, :exercise)
      .where{(task_step.first_completed_at != nil) & (task_step.tasks_task_id.in all_task_ids)}
      .group(exercise: :content_page_id)
    completed_core_tasked_exercises = completed_tasked_exercises.where(
      task_step: { group_type: Tasks::Models::TaskStep.group_types[:core_group] }
    )
    correct_core_tasked_exercises = completed_core_tasked_exercises.where{
      answer_id == correct_answer_id
    }
    completed_spaced_tasked_exercises = completed_tasked_exercises.where(
      task_step: { group_type: Tasks::Models::TaskStep.group_types[:spaced_practice_group] }
    )
    correct_spaced_tasked_exercises = completed_spaced_tasked_exercises.where{
      answer_id == correct_answer_id
    }

    original_performance_map = {}

    completed_core_counts = completed_core_tasked_exercises
                              .count('DISTINCT tasks_tasked_exercises.id')
    correct_core_counts = correct_core_tasked_exercises
                            .count('DISTINCT tasks_tasked_exercises.id')

    completed_core_counts.each do |page_id, completed_core_count|
      correct_core_count = correct_core_counts[page_id] || 0
      original_performance_map[page_id] = correct_core_count/completed_core_count.to_f
    end

    spaced_performance_map = {}

    completed_spaced_counts = completed_spaced_tasked_exercises
                                .count('DISTINCT tasks_tasked_exercises.id')
    correct_spaced_counts = correct_spaced_tasked_exercises
                              .count('DISTINCT tasks_tasked_exercises.id')

    completed_spaced_counts.each do |page_id, completed_spaced_count|
      correct_spaced_count = correct_spaced_counts[page_id] || 0
      spaced_performance_map[page_id] = correct_spaced_count/completed_spaced_count.to_f
    end

    [original_performance_map, spaced_performance_map]
  end

  def load_cc_stats(course)
    cc_tasks = Tasks::Models::ConceptCoachTask
      .joins([{task: [:task, {taskings: :period}]}])
      .preload([{task: [:task, {taskings: {period: :active_enrollments}}]}, {page: :chapter}])
      .where(task: {taskings: {period: {entity_course_id: course.id}}})
      .where{task.task.completed_exercise_steps_count > 0}
      .distinct.to_a

    outputs.course.periods = cc_tasks.group_by do |cc_task|
      # Does not support group work
      cc_task.task.taskings.first.period
    end.map do |period, cc_tasks|
      num_students = period.active_enrollments.length
      orig_map, spaced_map = get_period_performance_maps_from_cc_tasks(cc_tasks)

      {
        id: period.id,
        name: period.name,
        chapters: cc_tasks.group_by{ |cc_task| cc_task.page.chapter }
                          .map do |chapter, cc_tasks|
          {
            id: chapter.id,
            title: chapter.title,
            book_location: chapter.book_location,
            pages: cc_tasks.group_by(&:page).map do |page, cc_tasks|
              tasks = cc_tasks.map{ |cc_task| cc_task.task.task }

              completed = tasks.select(&:completed?).size
              in_progress = tasks.select(&:in_progress?).size
              not_started = num_students - (completed + in_progress)

              {
                id: page.id,
                title: page.title,
                book_location: page.book_location,
                completed: completed,
                in_progress: in_progress,
                not_started: not_started,
                original_performance: orig_map[page.id],
                spaced_practice_performance: spaced_map[page.id]
              }
            end.sort{ |a, b| b[:book_location] <=> a[:book_location] }
          }
        end.sort{ |a, b| b[:book_location] <=> a[:book_location] }
      }
    end
  end

  def load_course(course, role_type)
    teachers = run(:get_course_teachers, course).outputs.teachers

    outputs[:course] = {
      id: course.id,
      name: course.name,
      teachers: teachers
    }
  end

  def load_role(role, role_type)
    outputs.role = {
      id: role.id,
      type: role_type.to_s
    }
  end
end
