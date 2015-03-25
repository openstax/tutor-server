class Domain::AddBookToCourse
  lev_routine

  uses_routine CourseContent::Api::AddBookToCourse,
               translations: { outputs: {type: :verbatim} }

  protected

  def exec(course:, book:)
    run(CourseContent::Api::AddBookToCourse, course: course, book: book)
  end
end
