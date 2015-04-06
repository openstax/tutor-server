class Domain::GetUserCourseStats
  lev_routine express_output: :course_stats

  uses_routine CourseProfile::GetProfile,
    translations: { outputs: { type: :verbatim } },
    as: :get_course_profile

  uses_routine CourseContent::GetCourseBooks,
    translations: { outputs: { type: :verbatim } },
    as: :get_course_books

  uses_routine Content::VisitBook,
    translations: { outputs: { type: :verbatim } },
    as: :get_book_toc

  protected
  def exec(user:, course:)
    run(:get_course_profile, course.id)
    run(:get_course_books, course: course)
    compile_course_stats
  end

  private
  def compile_course_stats
    outputs[:course_stats] = {
      title: outputs.profile.name,
      topics: collect_book_parts
    }
  end

  def collect_book_parts
    outputs.book_parts.collect do |book_part|
      { id: book_part.id,
        title: book_part.title,
        number: book_part.path,
        page_ids: book_part.page_ids }
    end
  end
end
