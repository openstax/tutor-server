class GetTeacherGuide
  lev_routine express_output: :teacher_guide

  protected

  def exec(role:, current_time: Time.current)
    course = role.teacher.course
    periods = course.periods
    ecosystem = course.ecosystem
    book = ecosystem.books.first

    period_book_parts_by_period_id = Ratings::PeriodBookPart.where(
      period: periods
    ).group_by(&:course_membership_period_id)

    outputs.teacher_guide = periods.map do |period|
      period_book_parts = period_book_parts_by_period_id[period.id]
      period_book_parts_by_book_part_uuid = period_book_parts.index_by(&:book_part_uuid)

      chapter_guides = book.chapters.map do |chapter|
        chapter_period_book_part = period_book_parts_by_book_part_uuid[chapter.uuid]
        next if chapter_period_book_part.nil?

        page_guides = chapter.pages.map do |page|
          page_period_book_part = period_book_parts_by_book_part_uuid[page.uuid]
          next if page_period_book_part.nil?

          {
            title: page.title,
            book_location: page.book_location,
            student_count: page_period_book_part.num_students,
            questions_answered_count: page_period_book_part.num_responses,
            clue: page_period_book_part.clue,
            page_ids: [ page.id ],
            first_worked_at: page_period_book_part.created_at,
            last_worked_at: page_period_book_part.updated_at
          }
        end.compact

        {
          title: chapter.title,
          book_location: chapter.book_location,
          student_count: chapter_period_book_part.num_students,
          questions_answered_count: chapter_period_book_part.num_responses,
          clue: chapter_period_book_part.clue,
          page_ids: page_guides.map { |guide| guide[:page_ids] }.reduce([], :+),
          first_worked_at: chapter_period_book_part.created_at,
          last_worked_at: chapter_period_book_part.updated_at,
          children: page_guides
        }
      end.compact

      {
        period_id: period.id,
        title: book.title,
        page_ids: chapter_guides.map { |guide| guide[:page_ids] }.reduce([], :+),
        children: chapter_guides
      }
    end
  end
end
