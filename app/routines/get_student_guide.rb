class GetStudentGuide
  lev_routine express_output: :student_guide

  protected

  def exec(role:, current_time: Time.current)
    period = role.course_member.period
    course = period.course
    ecosystem = course.ecosystem
    book = ecosystem.books.first

    role_book_parts_by_book_part_uuid = Ratings::RoleBookPart.where(
      role: role
    ).index_by(&:book_part_uuid)

    chapter_guides = book.chapters.map do |chapter|
      chapter_role_book_part = role_book_parts_by_book_part_uuid[chapter.uuid]
      next if chapter_role_book_part.nil?

      page_guides = chapter.pages.map do |page|
        page_role_book_part = role_book_parts_by_book_part_uuid[page.uuid]
        next if page_role_book_part.nil?

        {
          title: page.title,
          book_location: page.book_location,
          student_count: 1,
          questions_answered_count: page_role_book_part.num_responses,
          clue: page_role_book_part.clue,
          page_ids: [ page.id ],
          first_worked_at: page_role_book_part.created_at,
          last_worked_at: page_role_book_part.updated_at
        }
      end.compact

      {
        title: chapter.title,
        book_location: chapter.book_location,
        student_count: 1,
        questions_answered_count: chapter_role_book_part.num_responses,
        clue: chapter_role_book_part.clue,
        page_ids: page_guides.map { |guide| guide[:page_ids] }.reduce([], :+),
        first_worked_at: chapter_role_book_part.created_at,
        last_worked_at: chapter_role_book_part.updated_at,
        children: page_guides
      }
    end.compact

    outputs.student_guide = {
      period_id: period.id,
      title: book.title,
      page_ids: chapter_guides.map { |guide| guide[:page_ids] }.reduce([], :+),
      children: chapter_guides
    }
  end
end
