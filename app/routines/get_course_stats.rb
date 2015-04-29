class GetCourseStats
  lev_routine express_output: :course_stats

  uses_routine Tasks::GetRoleCompletedTaskSteps,
    translations: { outputs: { type: :verbatim } },
    as: :get_role_task_steps

  uses_routine CourseContent::GetCourseBooks,
    translations: { outputs: { type: :verbatim } },
    as: :get_course_books

  uses_routine Content::VisitBook,
    translations: { outputs: { type: :verbatim } },
    as: :visit_book

  protected
  def exec(role:, course:)
    run(:get_role_task_steps, roles: role)
    run(:get_course_books, course: course)
    run(:visit_book, book: outputs.books.first, visitor_names: [:toc, :page_data])

    outputs[:course_stats] = { title: root_book_title, fields: compile_fields }
  end

  private
  def root_book_title
    outputs.toc.first.title
  end

  def compile_fields
    task_steps_grouped_by_book_part.collect do |book_part_id, task_steps|
      book_part = find_book_part(book_part_id)
      practices = completed_practices(
        task_steps: task_steps,
        task_type: :mixed_practice
      )

      { id: book_part.id,
        current_level: get_current_level(task_steps: task_steps),
        pages: compile_pages(task_steps: task_steps),
        practice_count: practices.count,
        questions_answered_count: task_steps.count,
        title: book_part.title,
        number: book_part.chapter_section }
    end
  end

  def task_steps_grouped_by_book_part
    outputs.task_steps.select { |t|
      t.tasked_type.ends_with?('TaskedExercise')
    }.group_by do |t|
      pages = Content::Routines::SearchPages[tag: get_lo_tags(task_steps: t)]
      pages.first.content_book_part_id
    end
  end

  def get_lo_tags(task_steps:)
    [task_steps].flatten.collect(&:tasked).flatten.collect(&:los).flatten.uniq
  end

  def compile_pages(task_steps:)
    tags = get_lo_tags(task_steps: task_steps)
    pages = Content::Routines::SearchPages[tag: tags, match_count: 1]

    pages.uniq.collect do |page|
      filtered_task_steps = filter_task_steps_by_page(task_steps: task_steps,
                                                      page: page)

      practices = completed_practices(
        task_steps: filtered_task_steps,
        task_type: :page_practice
      )

      { id: page.id,
        current_level: get_current_level(task_steps: filtered_task_steps),
        practice_count: practices.count,
        questions_answered_count: filtered_task_steps.count,
        title: page.title,
        number: page.chapter_section }
    end
  end

  def filter_task_steps_by_page(task_steps:, page:)
    page_data = outputs.page_data.select { |p| p.id == page.id }.first
    page_los = page_data.los
    task_steps.select do |task_step|
      (task_step.tasked.los & page_los).any?
    end
  end

  def completed_practices(task_steps:, task_type:)
    task_ids = task_steps.collect(&:tasks_task_id).uniq
    tasks = Tasks::Models::Task.where(id: task_ids, task_type: task_type)
    tasks.select(&:completed?)
  end

  def get_current_level(task_steps:)
    lo_tags = get_lo_tags(task_steps: task_steps)
    OpenStax::BigLearn::V1.get_clue(learner_ids: [], tags: lo_tags)
  end

  def find_book_part(id)
    toc_children = outputs.toc.collect(&:children).flatten
    book_part = outputs.toc.select { |bp| bp.id == id }.first
    book_part ||= toc_children.select { |bp| bp.id == id }.first
  end
end
