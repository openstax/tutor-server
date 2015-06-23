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

  uses_routine CourseMembership::GetCourseRoles,
    translations: { outputs: { type: :verbatim } },
    as: :get_course_roles

  uses_routine CourseMembership::IsCourseTeacher,
    translations: { outputs: { type: :verbatim } },
    as: :is_teacher

  protected
  def exec(role:, course:)
    @role, @course = role, course

    get_task_steps

    run(:get_course_books, course: course)
    run(:get_periods, course: course)
    run(:visit_book, book: outputs.books.first, visitor_names: [:toc, :page_data])

    outputs[:course_guide] = compile_course_guide
  end

  private
  attr_reader :role, :course

  def compile_course_guide
    if run(:is_teacher, course: course, roles: role).outputs.is_course_teacher
      outputs[:periods].collect do |period|
        {
          period_id: period.id,
          title: outputs.toc.title, # toc is root book
          page_ids: compile_chapters.collect { |cc| cc[:page_ids] }.flatten.uniq,
          children: compile_chapters
        }
      end
    else # only 1 period for student role
      [{ period: { id: outputs[:periods].last.id },
         stats: {
           title: outputs.toc.title, # toc is root book
           page_ids: compile_chapters.collect { |cc| cc[:page_ids] }.flatten.uniq,
           children: compile_chapters
         } }]
    end
  end

  def get_task_steps
    if run(:is_teacher, course: course, roles: role).outputs.is_course_teacher
      run(:get_course_roles, course: course, types: :student)
      run(:get_role_task_steps, roles: outputs.roles)
    else
      run(:get_role_task_steps, roles: role)
    end
  end

  def compile_chapters
    @chapters ||= task_steps_grouped_by_book_part.collect { |book_part_id, task_steps|
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

  def task_steps_grouped_by_book_part
    outputs.task_steps.select { |t|
      t.tasked_type.ends_with?('TaskedExercise')
    }.group_by do |t|
      pages = Content::Routines::SearchPages[tag: get_lo_tags(t)]
      pages.first.content_book_part_id
    end
  end

  def get_lo_tags(task_steps)
    [task_steps].flatten.collect(&:tasked).flatten.collect(&:los).flatten.uniq
  end

  def compile_pages(task_steps)
    tags = get_lo_tags(task_steps)
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
    task_steps.select do |task_step|
      (task_step.tasked.los & page_los).any?
    end
  end

  def completed_practices(task_steps, task_type)
    task_ids = task_steps.collect(&:tasks_task_id).uniq
    tasks = Tasks::Models::Task.where(id: task_ids, task_type: task_type)
    tasks.select(&:completed?)
  end

  def get_current_level(task_steps)
    lo_tags = get_lo_tags(task_steps)
    OpenStax::Biglearn::V1.get_clue(roles: role, tags: lo_tags)
  end

  def book_parts_by_id
    @book_parts_by_id ||= Hash[book_parts.map { |part| [part.id, part] }]
  end

  def book_parts
    [outputs.toc, outputs.toc.children].flatten
  end
end
