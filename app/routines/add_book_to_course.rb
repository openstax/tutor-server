class Domain::AddBookToCourse
  lev_routine

  uses_routine CourseContent::AddBookToCourse,
               translations: { outputs: {type: :verbatim} }

  protected

  def exec(course:, book:)
    run(CourseContent::AddBookToCourse, course: course, book: book)
  end
end
