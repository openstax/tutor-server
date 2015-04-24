class GetCourseStats
  lev_routine express_output: :course_stats

  uses_routine Tasks::GetRoleCompletedTaskSteps,
    translations: { outputs: { type: :verbatim } },
    as: :get_role_task_steps

  uses_routine Content::GetPage,
    translations: { outputs: { type: :verbatim } },
    as: :get_page

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
    run(:visit_book, book: outputs.books.first, visitor_names: :toc)
    run(:visit_book, book: outputs.books.first, visitor_names: :page_data)

    outputs[:course_stats] = { title: root_book_title,
                               fields: compile_fields(role: role) }
  end

  private
  def root_book_title
    outputs.toc.first.title
  end

  def compile_fields(role: role)
    task_steps_grouped_by_book_part.collect do |book_part_id, task_steps|
      book_part = find_book_part(book_part_id)
      practices = completed_practices(task_steps: task_steps)
      page_ids = task_steps.collect(&:page_id).flatten.uniq

      { id: book_part.id,
        current_level: get_current_level(page_ids: page_ids),
        pages: compile_pages(task_steps: task_steps),
        practice_count: practices.count,
        questions_answered_count: task_steps.count,
        title: book_part.title,
        number: book_part.path }
    end
  end

  def compile_pages(task_steps:)
    task_steps.collect(&:page_id).flatten.uniq.collect do |page_id|
      filtered_task_steps = task_steps.select { |ts| ts.page_id == page_id }
      page = outputs.page_data.select { |p| p.id == page_id }.first
      practices = completed_practices(task_steps: filtered_task_steps)

      { id: page.id,
        current_level: get_current_level(page_ids: page_id),
        practice_count: practices.count,
        questions_answered_count: filtered_task_steps.count,
        title: page.title,
        number: page.path }
    end
  end

  def completed_practices(task_steps:)
    tasks = Tasks::Models::Task.where(id: task_steps.collect(&:tasks_task_id).uniq)
                               .where{task_type == "practice"}
    tasks.select(&:completed?)
  end

  def get_current_level(page_ids:)
    lo_tags = get_lo_tags(page_ids: page_ids)
    OpenStax::BigLearn::V1.get_clue(learner_ids: [], tags: lo_tags)
  end

  def get_lo_tags(page_ids:)
    page_ids = [page_ids].flatten
    outputs.page_data.select { |p| page_ids.include?(p.id) }
                     .collect(&:los).flatten.uniq
  end

  def task_steps_grouped_by_book_part
    outputs.task_steps.select { |t|
      t.page_id.present? &&
        t.tasked_type == 'Tasks::Models::TaskedExercise' &&
          t.completed?
    }.group_by do |task_step|
      run(:get_page, id: task_step.page_id).outputs.page.book_part_id
    end
  end

  def find_book_part(id)
    toc_children = outputs.toc.collect(&:children).flatten
    book_part = outputs.toc.select { |bp| bp.id == id }.first
    book_part ||= toc_children.select { |bp| bp.id == id }.first
  end
end
