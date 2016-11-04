class GetCcDashboard
  # CC dashboard cache duration
  # The dashboard cache is invalidated each time a new exercise is answered
  # Otherwise, it will have the duration specified below
  DASHBOARD_CACHE_DURATION = 1.year

  include DashboardRoutineMethods

  protected

  def exec(course:, role:, start_at_ntz: nil, end_at_ntz: nil)
    unless course.is_concept_coach
      fatal_error(code: :non_cc_course)
      return
    end

    role_type = get_role_type(course, role)

    raise SecurityTransgression if role_type.nil?

    load_role(role, role_type)
    load_course(course, role_type)
    load_tasks(role, role_type, start_at_ntz, end_at_ntz)
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

  def map_cc_task_to_page(page_to_page_map, cc_task)
    # Map the cc_task page to a new page, but default to the original if the mapping failed
    cc_page = Content::Page.new(strategy: cc_task.page.wrap)
    page_to_page_map[cc_page] || cc_page
  end

  def load_cc_teacher_stats(course, role)
    cc_tasks = Tasks::Models::ConceptCoachTask
      .joins(task: {taskings: :period})
      .preload(task: {taskings: [:period, :role]}, page: :chapter)
      .where(task: {taskings: {period: {course_profile_course_id: course.id}}})
      .where{task.completed_exercise_steps_count > 0}
      .distinct.to_a

    # Does not support group work
    period_id_cc_tasks_map = cc_tasks.group_by{ |cc_task| cc_task.task.taskings.first.period.id }

    ecosystems_map = GetCourseEcosystemsMap[course: course]
    cc_task_pages = cc_tasks.map{ |cc_task| Content::Page.new(strategy: cc_task.page.wrap) }
    page_to_page_map = ecosystems_map.map_pages_to_pages(pages: cc_task_pages)

    outputs.course.periods = course.periods.preload(latest_enrollments: {student: :role})
                                           .map do |period|
      cc_tasks = period_id_cc_tasks_map[period.id] || []
      active_student_roles = period.latest_enrollments.map{ |en| en.student.role }.uniq
      orig_map, spaced_map = get_period_performance_maps_from_cc_tasks(period, cc_tasks,
                                                                       page_to_page_map)

      {
        id: period.id,
        name: period.name,
        chapters: cc_tasks.group_by do |cc_task|
          map_cc_task_to_page(page_to_page_map, cc_task).chapter
        end.map do |chapter, cc_tasks|
          {
            id: chapter.id,
            title: chapter.title,
            book_location: chapter.book_location,
            pages: cc_tasks.group_by do |cc_task|
              map_cc_task_to_page(page_to_page_map, cc_task)
            end.map do |page, cc_tasks|
              tasks = cc_tasks.map(&:task)
              completed_roles = tasks.select(&:completed?)
                                     .flat_map{ |task| task.taskings.map(&:role) }
                                     .uniq
              in_progress_roles = tasks.select(&:in_progress?)
                                       .flat_map{ |task| task.taskings.map(&:role) }
                                       .uniq
              not_started_roles = active_student_roles - (completed_roles + in_progress_roles)

              {
                id: page.id,
                title: page.title,
                uuid: page.uuid,
                version: page.version,
                book_location: page.book_location,
                completed: completed_roles.size,
                in_progress: in_progress_roles.size,
                not_started: not_started_roles.size,
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
      .joins(task: :taskings)
      .preload(task: {tasked_exercises: :task_step}, page: :chapter)
      .where(task: {taskings: {entity_role_id: role.id}})
      .where{task.completed_exercise_steps_count > 0}
      .distinct.to_a

    ecosystems_map = GetCourseEcosystemsMap[course: role.student.course]
    cc_task_pages = cc_tasks.map{ |cc_task| Content::Page.new(strategy: cc_task.page.wrap) }
    page_to_page_map = ecosystems_map.map_pages_to_pages(pages: cc_task_pages)

    outputs.chapters = cc_tasks.group_by do |cc_task|
      map_cc_task_to_page(page_to_page_map, cc_task).chapter
    end.map do |chapter, cc_tasks|
      {
        id: chapter.id,
        title: chapter.title,
        book_location: chapter.book_location,
        pages: cc_tasks.group_by{ |cc_task| map_cc_task_to_page(page_to_page_map, cc_task) }
                       .map do |page, cc_tasks|
          tasks = cc_tasks.map(&:task)
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

  def get_period_performance_maps_from_cc_tasks(period, cc_tasks, page_to_page_map)
    all_task_ids = cc_tasks.map{ |cc_task| cc_task.task.id }
    all_page_models = cc_tasks.map{ |cc_task| cc_task.page }.uniq
    all_pages = all_page_models.map{ |page_model| Content::Page.new(strategy: page_model.wrap) }

    completed_tasked_exercises = Tasks::Models::TaskedExercise
      .joins(:task_step, :exercise)
      .where{(task_step.first_completed_at != nil) & (task_step.tasks_task_id.in all_task_ids)}
      .group(exercise: :content_page_id)
    last_answer_times = completed_tasked_exercises.maximum('tasks_task_steps.last_completed_at')

    cache_key_to_page_map = all_pages.each_with_object({}) do |page, hash|
      cache_key = "dashboard/cc/teacher/#{period.id}/#{page.id}-#{last_answer_times[page.id]}"
      hash[cache_key] = page
    end

    all_cache_keys = cache_key_to_page_map.keys
    cache_key_performance_map = all_cache_keys.empty? ? \
                                  {} : Rails.cache.read_multi(*all_cache_keys)

    performance_map = {}
    hit_cache_keys = []

    cache_key_performance_map.each do |cache_key, performance|
      # Ignore values cached before the cache format change
      next if performance[:original_count].nil? && performance[:spaced_count].nil?

      page = cache_key_to_page_map[cache_key]
      performance_map[page] = performance
      hit_cache_keys << cache_key
    end

    missed_cache_keys = all_cache_keys - hit_cache_keys

    unless missed_cache_keys.empty?
      missed_page_to_cache_key_map = missed_cache_keys.each_with_object({}) do |cache_key, hash|
        page = cache_key_to_page_map[cache_key]
        hash[page] = cache_key
      end
      missed_page_ids = missed_page_to_cache_key_map.keys.map(&:id)

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

      missed_page_to_cache_key_map.each do |page, cache_key|
        completed_core_count = missed_completed_core_counts[page.id] || 0
        completed_spaced_count = missed_completed_spaced_counts[page.id] || 0
        correct_core_count = missed_correct_core_counts[page.id] || 0
        correct_spaced_count = missed_correct_spaced_counts[page.id] || 0
        original_performance = completed_core_count == 0 ? \
                                 0 : correct_core_count/completed_core_count.to_f
        spaced_performance = completed_spaced_count == 0 ? \
                               0 : correct_spaced_count/completed_spaced_count.to_f
        performance = { original: original_performance, original_count: completed_core_count,
                        spaced: spaced_performance, spaced_count: completed_spaced_count }

        Rails.cache.write(cache_key, performance, expires_in: DASHBOARD_CACHE_DURATION)

        performance_map[page] = performance
      end
    end

    original_performance_map = {}
    original_performance_counts = {}
    spaced_performance_map = {}
    spaced_performance_counts = {}

    # Map the performance map to current ecosystem pages
    performance_map.each do |page, performance|
      mapped_page_id = page_to_page_map[page].id

      previous_original_count = original_performance_counts[mapped_page_id] || 0
      previous_original_performance = original_performance_map[mapped_page_id] || 0
      new_original_count = previous_original_count + performance[:original_count]
      new_original_performance = new_original_count == 0 ? nil : \
                                   (previous_original_performance*previous_original_count + \
                                    performance[:original]*performance[:original_count])/ \
                                   new_original_count
      original_performance_counts[mapped_page_id] = new_original_count
      original_performance_map[mapped_page_id] = new_original_performance

      previous_spaced_count = spaced_performance_counts[mapped_page_id] || 0
      previous_spaced_performance = spaced_performance_map[mapped_page_id] || 0
      new_spaced_count = previous_spaced_count + performance[:spaced_count]
      new_spaced_performance = new_spaced_count == 0 ? nil : \
                                 (previous_spaced_performance*previous_spaced_count + \
                                  performance[:spaced]*performance[:spaced_count])/new_spaced_count
      spaced_performance_counts[mapped_page_id] = new_spaced_count
      spaced_performance_map[mapped_page_id] = new_spaced_performance
    end

    [original_performance_map, spaced_performance_map]
  end
end
