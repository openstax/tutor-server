class GetCcDashboard
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
      .with_deleted # speed up query, the join on cc_page_stats removes deleted
      .joins('join cc_page_stats cc_page_stats on ' \
              'cc_page_stats.task_ids @> array[tasks_concept_coach_tasks.tasks_task_id]')
      .where(['cc_page_stats.course_id = ?', course.id])
      .select([
                :id,
                :tasks_task_id,
                :content_page_id,
                { cc_page_stats: [ :course_period_id, :completed_steps_count, :steps_count, :role_ids ] }
              ])
      .preload(page: :chapter)
      .to_a
    period_id_cc_tasks_map = cc_tasks.group_by(&:course_period_id)

    ecosystems_map = GetCourseEcosystemsMap[course: course]

    cc_task_pages = cc_tasks.map{ |cc_task| Content::Page.new(strategy: cc_task.page.wrap) }
    page_to_page_map = ecosystems_map.map_pages_to_pages(pages: cc_task_pages)

    outputs.course.periods = course.periods.preload(latest_enrollments: :student).map do |period|
      cc_tasks = period_id_cc_tasks_map[period.id] || []
      active_role_ids = period.latest_enrollments.map { |en| en.student.entity_role_id }.uniq
      core_map, spaced_map = get_period_performance_maps_from_cc_tasks(
        period, cc_tasks, ecosystems_map
      )

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
              completed_cc_tasks, in_progress_cc_tasks = cc_tasks.partition do |cc_task|
                cc_task.completed_steps_count == cc_task.steps_count
              end
              completed_role_ids = completed_cc_tasks.flat_map(&:role_ids).uniq
              in_progress_role_ids = in_progress_cc_tasks.flat_map(&:role_ids).uniq
              not_started_role_ids = active_role_ids - (completed_role_ids + in_progress_role_ids)

              {
                id: page.id,
                title: page.title,
                uuid: page.uuid,
                version: page.version,
                book_location: page.book_location,
                completed: completed_role_ids.size,
                in_progress: in_progress_role_ids.size,
                not_started: not_started_role_ids.size,
                original_performance: core_map[page.id],
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

  def get_period_performance_maps_from_cc_tasks(period, cc_tasks, ecosystems_map)

    all_pages_with_stats = Content::Models::Page.joins(
      'join cc_page_stats on cc_page_stats.content_page_id = content_pages.id'
    ).where(['cc_page_stats.course_period_id = ?', period.id]).select('*')

    all_page_wrappers = all_pages_with_stats.map { |page| Content::Page.new(strategy: page.wrap) }
    page_to_page_map = ecosystems_map.map_pages_to_pages(pages: all_page_wrappers)

    core_performance_map = {}
    core_performance_counts = Hash.new(0)
    spaced_performance_map = {}
    spaced_performance_counts = Hash.new(0)
    core_group_type = Tasks::Models::TaskStep.group_types[:core_group]
    spaced_practice_group_type = Tasks::Models::TaskStep.group_types[:spaced_practice_group]
    all_pages_with_stats.group_by(&:id).each do |page_id, pages_with_stats|
      indexed_pages_with_stats = pages_with_stats.index_by(&:group_type)

      # Calculate performance for the core page
      core_page_with_stats = indexed_pages_with_stats[core_group_type]

      # Skip if no core page (if core and spaced practice happened with different course ecosystems)
      if core_page_with_stats.present?
        core_completed_count = core_page_with_stats.completed_steps_count
        core_correct_count = core_page_with_stats.correct_count
        core_performance = core_correct_count/core_completed_count.to_f

        # Map the core page to a current page
        wrapped_core_page = Content::Page.new(strategy: core_page_with_stats.wrap)
        mapped_core_page_id = page_to_page_map[wrapped_core_page].id

        # Update the current page's stats
        previous_core_count = core_performance_counts[mapped_core_page_id]
        previous_core_performance = core_performance_map[mapped_core_page_id] || 0
        new_core_count = previous_core_count + core_completed_count
        new_core_performance = new_core_count == 0 ? nil : \
                                 (previous_core_performance * previous_core_count + \
                                  core_performance * core_completed_count)/new_core_count
        core_performance_counts[mapped_core_page_id] = new_core_count
        core_performance_map[mapped_core_page_id] = new_core_performance
      end

      # Calculate performance for the spaced page
      spaced_page_with_stats = indexed_pages_with_stats[spaced_practice_group_type]

      # Skip if spaced practice hasn't happened yet
      next if spaced_page_with_stats.nil?

      spaced_completed_count = spaced_page_with_stats.completed_steps_count
      spaced_correct_count = spaced_page_with_stats.correct_count
      spaced_performance = spaced_correct_count/spaced_completed_count.to_f

      # Map the spaced page to a current page
      wrapped_spaced_page = Content::Page.new(strategy: spaced_page_with_stats.wrap)
      mapped_spaced_page_id = page_to_page_map[wrapped_spaced_page].id

      # Update the current page's stats
      previous_spaced_count = spaced_performance_counts[mapped_spaced_page_id]
      previous_spaced_performance = spaced_performance_map[mapped_spaced_page_id] || 0
      new_spaced_count = previous_spaced_count + spaced_completed_count
      new_spaced_performance = new_spaced_count == 0 ? nil : \
                               (previous_spaced_performance * previous_spaced_count + \
                                spaced_performance * spaced_completed_count)/new_spaced_count
      spaced_performance_counts[mapped_spaced_page_id] = new_spaced_count
      spaced_performance_map[mapped_spaced_page_id] = new_spaced_performance
    end

    [core_performance_map, spaced_performance_map]
  end
end
