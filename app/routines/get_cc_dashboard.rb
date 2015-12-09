class GetCcDashboard
  # CC dashboard cache duration
  # The dashboard cache is invalidated each time a new exercise is answered
  # Otherwise, it will have the duration specified below
  DASHBOARD_CACHE_DURATION = 1.year

  include DashboardRoutineMethods

  protected

  def exec(course:, role:)
    unless course.is_concept_coach
      fatal_error(code: :non_cc_course)
      return
    end

    role_type = get_role_type(course, role)

    raise SecurityTransgression if role_type.nil?

    load_role(role, role_type)
    load_course(course, role_type)
    load_tasks(role, role_type)
    load_cc_stats(course, role, role_type)
  end

  def load_cc_stats(course, role, role_type)
    case role_type
    when :teacher
      load_cc_teacher_stats(course, role)
    when :student
      load_cc_student_stats(role)
    end
  end

  def map_cc_task_to_page(page_id_to_page_map, cc_task)
    # Map the cc_task page to a new page, but default to the original if the mapping failed
    page_id_to_page_map[cc_task.page.id] || Content::Page.new(strategy: cc_task.page.wrap)
  end

  def load_cc_teacher_stats(course, role)
    cc_tasks = Tasks::Models::ConceptCoachTask
      .joins(task: [:task, {taskings: :period}])
      .preload(task: [:task, {taskings: {period: :active_enrollments}}], page: :chapter)
      .where(task: {taskings: {period: {entity_course_id: course.id}}})
      .where{task.task.completed_exercise_steps_count > 0}
      .distinct.to_a

    # Does not support group work
    period_id_cc_tasks_map = cc_tasks.group_by{ |cc_task| cc_task.task.taskings.first.period.id }

    ecosystems_map = GetCourseEcosystemsMap[course: course]
    cc_task_pages = cc_tasks.map{ |cc_task| Content::Page.new(strategy: cc_task.page.wrap) }
    page_id_to_page_map = ecosystems_map.map_pages_to_pages(pages: cc_task_pages)

    outputs.course.periods = course.periods.map do |period|
      cc_tasks = period_id_cc_tasks_map[period.id] || []
      num_students = period.active_enrollments.length
      orig_map, spaced_map = get_period_performance_maps_from_cc_tasks(period, cc_tasks)

      {
        id: period.id,
        name: period.name,
        chapters: cc_tasks.group_by do |cc_task|
          map_cc_task_to_page(page_id_to_page_map, cc_task).chapter
        end.map do |chapter, cc_tasks|
          {
            id: chapter.id,
            title: chapter.title,
            book_location: chapter.book_location,
            pages: cc_tasks.group_by do |cc_task|
              map_cc_task_to_page(page_id_to_page_map, cc_task)
            end.map do |page, cc_tasks|
              tasks = cc_tasks.map{ |cc_task| cc_task.task.task }

              completed = tasks.select(&:completed?).size
              in_progress = tasks.select(&:in_progress?).size
              not_started = num_students - (completed + in_progress)

              {
                id: page.id,
                title: page.title,
                uuid: page.uuid,
                version: page.version,
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

  def load_cc_student_stats(role)
    cc_tasks = Tasks::Models::ConceptCoachTask
      .joins(task: [:task, :taskings])
      .preload(task: {task: {tasked_exercises: :task_step}}, page: :chapter)
      .where(task: {taskings: {entity_role_id: role.id}})
      .where{task.task.completed_exercise_steps_count > 0}
      .distinct.to_a

    outputs.chapters = cc_tasks.group_by{ |cc_task| cc_task.page.chapter }
                               .map do |chapter, cc_tasks|
      {
        id: chapter.id,
        title: chapter.title,
        book_location: chapter.book_location,
        pages: cc_tasks.group_by(&:page).map do |page, cc_tasks|
          tasks = cc_tasks.map{ |cc_task| cc_task.task.task }
          tasked_exercises = tasks.flat_map(&:tasked_exercises)

          {
            id: page.id,
            title: page.title,
            uuid: page.uuid,
            version: page.version,
            book_location: page.book_location,
            last_worked_at: tasks.max_by(&:last_worked_at).last_worked_at,
            exercises: tasked_exercises.sort_by{ |te| te.task_step.number }.map do |te|
              {
                id: te.content_exercise_id,
                is_completed: te.task_step.completed?,
                is_correct: te.is_correct?
              }
            end
          }
        end.sort{ |a, b| b[:book_location] <=> a[:book_location] }
      }
    end.sort{ |a, b| b[:book_location] <=> a[:book_location] }
  end

  def get_period_performance_maps_from_cc_tasks(period, cc_tasks)
    all_task_ids = cc_tasks.map{ |cc_task| cc_task.task.task.id }
    all_page_ids = cc_tasks.map{ |cc_task| cc_task.page.id }.uniq

    completed_tasked_exercises = Tasks::Models::TaskedExercise
      .joins(:task_step, :exercise)
      .where{(task_step.first_completed_at != nil) & (task_step.tasks_task_id.in all_task_ids)}
      .group(exercise: :content_page_id)
    last_answer_times = completed_tasked_exercises.maximum('tasks_task_steps.last_completed_at')

    cache_key_to_page_id_map = all_page_ids.each_with_object({}) do |page_id, hash|
      cache_key = "dashboard/cc/teacher/#{period.id}/#{page_id}-#{last_answer_times[page_id]}"
      hash[cache_key] = page_id
    end

    all_cache_keys = cache_key_to_page_id_map.keys
    cache_key_performance_map = all_cache_keys.empty? ? {} : \
                                                        Rails.cache.read_multi(*all_cache_keys)

    original_performance_map = {}
    spaced_performance_map = {}

    cache_key_performance_map.each do |cache_key, performance|
      page_id = cache_key_to_page_id_map[cache_key]
      original_performance_map[page_id] = performance[:original]
      spaced_performance_map[page_id] = performance[:spaced]
    end

    missed_cache_keys = all_cache_keys - cache_key_performance_map.keys

    unless missed_cache_keys.empty?
      missed_page_id_to_cache_key_map = missed_cache_keys.each_with_object({}) do |cache_key, hash|
        page_id = cache_key_to_page_id_map[cache_key]
        hash[page_id] = cache_key
      end
      missed_page_ids = missed_page_id_to_cache_key_map.keys

      missed_completed_tasked_exercises = completed_tasked_exercises.where(
        exercise: { content_page_id: missed_page_ids }
      )
      missed_completed_core_tasked_exercises = missed_completed_tasked_exercises.where(
        task_step: { group_type: Tasks::Models::TaskStep.group_types[:core_group] }
      )
      missed_correct_core_tasked_exercises = missed_completed_core_tasked_exercises.where{
        answer_id == correct_answer_id
      }
      missed_completed_spaced_tasked_exercises = missed_completed_tasked_exercises.where(
        task_step: { group_type: Tasks::Models::TaskStep.group_types[:spaced_practice_group] }
      )
      missed_correct_spaced_tasked_exercises = missed_completed_spaced_tasked_exercises.where{
        answer_id == correct_answer_id
      }

      missed_completed_core_counts = missed_completed_core_tasked_exercises
                                       .count('DISTINCT tasks_tasked_exercises.id')
      missed_correct_core_counts = missed_correct_core_tasked_exercises
                                     .count('DISTINCT tasks_tasked_exercises.id')
      missed_completed_spaced_counts = missed_completed_spaced_tasked_exercises
                                         .count('DISTINCT tasks_tasked_exercises.id')
      missed_correct_spaced_counts = missed_correct_spaced_tasked_exercises
                                       .count('DISTINCT tasks_tasked_exercises.id')

      missed_page_id_to_cache_key_map.each do |page_id, cache_key|
        completed_core_count = missed_completed_core_counts[page_id] || 0
        completed_spaced_count = missed_completed_spaced_counts[page_id] || 0
        correct_core_count = missed_correct_core_counts[page_id] || 0
        correct_spaced_count = missed_correct_spaced_counts[page_id] || 0
        original_performance = completed_core_count == 0 ? \
                                 nil : correct_core_count/completed_core_count.to_f
        spaced_performance = completed_spaced_count == 0 ? \
                               nil : correct_spaced_count/completed_spaced_count.to_f
        performance = { original: original_performance, spaced: spaced_performance }

        Rails.cache.write(cache_key, performance, expires_in: DASHBOARD_CACHE_DURATION)

        original_performance_map[page_id] = performance[:original]
        spaced_performance_map[page_id] = performance[:spaced]
      end
    end

    [original_performance_map, spaced_performance_map]
  end
end
