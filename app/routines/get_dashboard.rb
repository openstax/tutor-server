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

  def get_period_performance_map_from_cc_tasks(cc_tasks)
    all_tasked_exercises = cc_tasks.flat_map{ |cc_task| cc_task.task.task.tasked_exercises }
    completed_tasked_exercises = all_tasked_exercises.map{ |te| te.task_step.completed? }

    completed_tasked_exercises.group_by{ |te| te.exercise.page }
                                                .each_with_object({}) do |hash, (page, tes)|
      orig_completed_tes = tes.select{ |te| te.task_step.core_group? }
      orig_correct_tes = orig_completed_tes.select(&:is_correct?)
      orig_performance = orig_completed_tes.size == 0 ? nil : \
                           orig_correct_tes.size/orig_completed_tes.size.to_f

      sp_completed_tes = tes.select{ |te| te.task_step.spaced_practice_group? }
      sp_correct_tes = sp_completed_tes.select(&:is_correct?)
      sp_performance = sp_completed_tes.size == 0 ? nil : \
                         sp_correct_tes.size/sp_completed_tes.size.to_f

      hash[page.id] = {
        original: orig_performance,
        spaced_practice: sp_performance
      }
    end
  end

  def load_cc_stats(course)
    cc_tasks = Tasks::Models::ConceptCoachTask
      .joins([{task: [:task, {taskings: :period}]}])
      .preload([{task: [{task: {tasked_exercises: [:task_step, {exercise: :page}]}},
                {taskings: {period: :students}}]},
                {page: :chapter}])
      .where(task: {taskings: {period: {entity_course_id: course.id}}})
      .where{task.task.completed_exercise_steps_count > 0}
      .distinct.to_a

    outputs.course.periods = cc_tasks.group_by do |cc_task|
      cc_task.task.task.taskings.first.period
    end.map do |period, cc_tasks|
      num_students = period.students.size
      performance_map = get_period_performance_map_from_cc_tasks(cc_tasks)

      {
        id: period.id,
        name: period.name,
        chapters: cc_tasks.group_by{ |cc_task| cc_task.page.chapter }
                          .map do |chapter, cc_tasks|
          {
            id: chapter.id,
            title: chapter.title,
            pages: cc_tasks.group_by(&:page).map do |page, cc_tasks|
              tasks = cc_tasks.map{ |cc_task| cc_task.task.task }

              completed = tasks.select(&:completed?).size
              in_progress = tasks.select(&:in_progress?).size
              not_started = num_students - (completed + in_progress)

              performance = performance_map[page.id] || {}

              {
                id: page.id,
                title: page.title,
                completed: completed,
                in_progress: in_progress,
                not_started: not_stated,
                original_performance: performance[:original],
                spaced_practice_performance: performance[:spaced_practice]
              }
            end
          }
        end
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
