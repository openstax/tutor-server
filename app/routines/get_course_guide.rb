class GetCourseGuide
  lev_routine express_output: :course_guide

  uses_routine Tasks::GetRoleCompletedTaskSteps,
    translations: { outputs: { type: :verbatim } },
    as: :get_role_task_steps

  uses_routine CourseContent::GetCourseBooks,
    translations: { outputs: { type: :verbatim } },
    as: :get_course_books

  uses_routine Content::VisitBook,
    translations: { outputs: { type: :verbatim } },
    as: :visit_book

  uses_routine CourseMembership::GetCoursePeriods,
    translations: { outputs: { type: :verbatim } },
    as: :get_periods

  uses_routine CourseMembership::GetPeriodRoles,
    translations: { outputs: { type: :verbatim } },
    as: :get_period_roles

  uses_routine CourseMembership::IsCourseTeacher,
    translations: { outputs: { type: :verbatim } },
    as: :is_teacher

  protected
  def exec(role:, course:)
    @role, @course = role, course

    run(:get_course_books, course: course)
    run(:get_periods, course: course, roles: role)
    run(:visit_book, book: outputs.books.first, visitor_names: [:toc, :page_data])

    get_role_completed_task_steps

    outputs.course_guide = if is_teacher?
                             gather_course_stats_for_teacher
                           else
                             gather_course_stats
                           end
  end

  private
  attr_reader :role, :course

  def gather_course_stats_for_teacher
    outputs.periods.collect do |period|
      { period_id: period.id }.merge(gather_course_stats)
    end
  end

  def gather_course_stats
    chapters = compile_chapters

    { title: outputs.toc.title,
      page_ids: chapters.collect { |cc| cc[:page_ids] }.flatten.uniq,
      children: chapters }
  end

  def get_role_completed_task_steps
    if is_teacher?
      run(:get_period_roles, periods: outputs.periods, types: :student)
      run(:get_role_task_steps, roles: outputs.roles)
    else
      outputs.roles = [role]
      run(:get_role_task_steps, roles: role)
    end
  end

  def compile_chapters
    exercises_grouped_by_book_part.collect { |book_part_id, task_steps|
      task_steps = filter_task_steps_by_period_roles(task_steps)
      book_part = book_parts_by_id[book_part_id]
      practices = completed_practices(task_steps, :mixed_practice)
      pages = compile_pages(task_steps)

      {
        id: book_part.id,
        title: book_part.title,
        chapter_section: book_part.chapter_section,
        questions_answered_count: task_steps.count,
        current_level: get_current_level(task_steps),
        practice_count: practices.count,
        page_ids: pages.collect { |pp| pp[:id] },
        children: pages
      }
    }.sort_by { |ch| ch[:chapter_section] }
  end

  def filter_task_steps_by_period_roles(task_steps)
    role_ids = outputs.roles.flatten.collect(&:id)

    task_steps.select do |task_step|
      task_step.task.taskings.where(entity_role_id: role_ids).any?
    end
  end

  def exercises_grouped_by_book_part
    outputs.task_steps.flatten.select { |t| t.exercise? && t.completed? }.group_by do |t|
      tags = get_lo_tags(t) + get_aplo_tags(t)
      Content::Routines::SearchPages[tag: tags].first.content_book_part_id
    end
  end

  def get_lo_tags(task_steps)
    [task_steps].flatten.collect(&:tasked).flatten.collect(&:los).flatten.uniq
  end

  def get_aplo_tags(task_steps)
    [task_steps].flatten.collect(&:tasked).flatten.collect(&:aplos).flatten.uniq
  end

  def compile_pages(task_steps)
    tags = get_lo_tags(task_steps) + get_aplo_tags(task_steps)
    pages = Content::Routines::SearchPages[tag: tags, match_count: 1]

    pages.uniq.collect { |page|
      filtered_task_steps = filter_task_steps_by_page(task_steps, page)
      practices = completed_practices(filtered_task_steps, :page_practice)

      { id: page.id,
        title: page.title,
        chapter_section: page.chapter_section,
        questions_answered_count: filtered_task_steps.count,
        current_level: get_current_level(filtered_task_steps),
        practice_count: practices.count,
        page_ids: [page.id]
      }
    }.sort_by { |page| page[:chapter_section] }
  end

  def filter_task_steps_by_page(task_steps, page)
    page_data = outputs.page_data.select { |p| p.id == page.id }.first
    page_los = page_data.los
    page_aplos = page_data.aplos
    task_steps.select do |task_step|
      (task_step.tasked.los & page_los).any? || (task_step.tasked.aplos & page_aplos).any?
    end
  end

  def completed_practices(task_steps, task_type)
    task_ids = task_steps.collect(&:tasks_task_id).uniq
    tasks = Tasks::Models::Task.where(id: task_ids, task_type: task_type)
    tasks.select(&:completed?)
  end

  def get_current_level(task_steps)
    tags = get_lo_tags(task_steps) + get_aplo_tags(task_steps)

    if is_teacher?
      OpenStax::Biglearn::V1.get_clue(roles: outputs.roles, tags: tags)
    else
      OpenStax::Biglearn::V1.get_clue(roles: role, tags: tags)
    end
  end

  def book_parts_by_id
    @book_parts_by_id ||= Hash[book_parts.map { |part| [part.id, part] }]
  end

  def book_parts
    [outputs.toc, outputs.toc.children].flatten
  end

  def is_teacher?
    @is_teacher ||= run(:is_teacher, course: course, roles: role).outputs.is_course_teacher
  end
end
