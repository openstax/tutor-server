class GetCourseGuide
  lev_routine express_output: :course_guide

  uses_routine CourseContent::GetCourseBooks,
    translations: { outputs: { type: :verbatim } },
    as: :get_course_books

  uses_routine CourseMembership::GetCoursePeriods,
    translations: { outputs: { type: :verbatim } },
    as: :get_periods

  protected

  def exec(role:, course:)
    run(:get_course_books, course: course)
    run(:get_periods, course: course, roles: role)

    outputs.course_guide = gather_course_stats_for_teacher
  end

  private

  def gather_course_stats_for_teacher
    outputs.periods.collect do |period|
      period_stats_per_book = gather_period_stats(period)
      period_stats_per_book.collect{ |book_stats| { period_id: period.id }.merge(book_stats) }
      # Assume only 1 book for now
      period_stats_per_book.first
    end
  end

  def completed_task_steps_for_period(period)
    period.enrollments.latest.active.preload(
      student: {role: {taskings: {task: {task: {task_steps: [{task: {taskings: :role}},
                                                              :tasked]}}}}}
    ).collect{ |en| en.student.role.taskings.collect{ |ts| ts.task.task.task_steps } }
     .flatten.select(&:completed?)
  end

  def group_exercises_by_related_content(exercises, rc_key = nil)
    result = {}
    exercises.flatten.select{ |ts| ts.exercise? && ts.completed? }.each do |ts|
      ts.related_content.each do |related_content|
        result_key = rc_key.nil? ? related_content : related_content[rc_key]
        next if result_key.nil?

        result[result_key] ||= []
        result[result_key] << ts
      end
    end
    result
  end

  def completed_practices(task_steps, task_type)
    task_steps.collect(&:task).select{ |task| task.task_type == task_type && task.completed? }.uniq
  end

  def get_los(task_steps)
    [task_steps].flatten.collect(&:los).flatten.uniq
  end

  def get_aplos(task_steps)
    [task_steps].flatten.collect(&:aplos).flatten.uniq
  end

  def get_current_level(task_steps)
    tags = get_los(task_steps) + get_aplos(task_steps)
    roles = task_steps.collect{ |ts| ts.task.taskings.collect{ |tg| tg.role } }.flatten.uniq
    OpenStax::Biglearn::V1.get_clue(roles: roles, tags: tags)
  end

  def compile_pages(task_steps)
    group_exercises_by_related_content(task_steps, :page).collect do |related_content, steps|
      practices = completed_practices(steps, :mixed_practice)

      {
        title: related_content[:title],
        chapter_section: related_content[:chapter_section],
        questions_answered_count: steps.count,
        current_level: get_current_level(steps),
        practice_count: practices.count,
        page_ids: [related_content[:id]]
      }
    end.sort_by{ |ch| ch[:chapter_section] }
  end

  def compile_chapters(task_steps)
    group_exercises_by_related_content(task_steps, :chapter).collect do |related_content,
                                                                           task_steps|
      practices = completed_practices(task_steps, :mixed_practice)
      pages = compile_pages(task_steps)

      {
        title: related_content[:title],
        chapter_section: related_content[:chapter_section],
        questions_answered_count: task_steps.count,
        current_level: get_current_level(task_steps),
        practice_count: practices.count,
        page_ids: pages.collect{|pp| pp[:page_ids]}.flatten.uniq,
        pages: pages
      }
    end.sort_by{ |ch| ch[:chapter_section] }
  end

  def compile_books(task_steps)
    group_exercises_by_related_content(task_steps, :book).collect do |related_content, task_steps|
      chapters = compile_chapters(task_steps)

      {
        title: related_content[:title],
        page_ids: chapters.collect{ |cc| cc[:page_ids] }.flatten,
        children: chapters
      }
    end.sort_by{ |bk| bk[:title] }
  end

  def gather_period_stats(period)
    task_steps = completed_task_steps_for_period(period)
    compile_books(task_steps)
  end
end
