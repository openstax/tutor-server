class GetCourseStats
  lev_routine express_output: :course_stats

  uses_routine Tasks::GetTasks,
    translations: { outputs: { type: :verbatim } },
    as: :get_tasks

  uses_routine CourseContent::GetCourseBooks,
    translations: { outputs: { type: :verbatim } },
    as: :get_course_books

  uses_routine Content::VisitBook,
    translations: { outputs: { type: :verbatim } },
    as: :get_book_toc

  protected
  def exec(role:, course:)
    run(:get_tasks, roles: role)
    run(:get_course_books, course: course)
    run(:get_book_toc, book: outputs.books.first, visitor_names: :toc)
    compile_course_stats
  end

  private
  def compile_course_stats
    outputs[:course_stats] = {
      title: outputs.toc.first.title, # should be root book
      fields: compile_toc_for_fields
    }
  end

  def compile_toc_for_fields
    binding.pry
    outputs.toc.from(1).map do |toc| # skip the root book for fields
      next if toc.title.match(/preface/i)
      translate_toc(toc)
    end
  end

  def translate_toc(toc)
    { id: toc.id,
      title: toc.title,
      questions_answered_count: rand(50),
      current_level: rand(0.0..1.0),
      practice_count: rand(30),
      unit: toc.path,
      page_ids: (toc.children || []).collect(&:id) }
  end
end
