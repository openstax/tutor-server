module Sprint009
  class CourseStats
    lev_routine express_output: :course

    uses_routine CreateCourse,
      translations: { outputs: { type: :verbatim } },
      as: :create_course

    uses_routine FetchAndImportBook,
      translations: { outputs: { type: :verbatim } },
      as: :fetch_and_import_book

    uses_routine AddBookToCourse,
      translations: { outputs: { type: :verbatim } },
      as: :add_book_to_course

    protected
    def exec
      run(:create_course)
      run(:fetch_and_import_book, id: '031da8d3-b525-429c-80cf-6c8ed997733a')
      run(:add_book_to_course, course: outputs.course, book: outputs.book)
    end
  end
end
