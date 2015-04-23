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
      page_ids = task_steps.collect(&:page_id).uniq
      lo_tags = outputs.page_data.select { |p| page_ids.include?(p.id) }
                                 .collect(&:los).flatten.uniq
      current_level = OpenStax::BigLearn::V1.get_clue(learner_ids: [],
                                                      tags: lo_tags)

      { id: book_part.id,
        current_level: current_level,
        pages: [], # coming soon
        practice_count: rand(30),
        questions_answered_count: completed_tasked_exercises(task_steps).count,
        title: book_part.title,
        unit: book_part.path }
    end
  end

  def completed_tasked_exercises(task_steps)
    task_steps.keep_if do |t|
      t.tasked_type == 'Tasks::Models::TaskedExercise' && t.completed?
    end
  end

  def task_steps_grouped_by_book_part
    outputs.task_steps.select { |t| t.page_id.present? }.group_by do |task_step|
      run(:get_page, id: task_step.page_id).outputs.page.book_part_id
    end
  end

  def find_book_part(id)
    toc_children = outputs.toc.collect(&:children).flatten
    book_part = outputs.toc.first { |bp| bp.id == id }
    book_part ||= toc_children.first { |bp| bp.id == id }
  end
end
