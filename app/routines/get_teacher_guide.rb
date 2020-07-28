class GetTeacherGuide
  lev_routine express_output: :teacher_guide

  protected

  def exec(role:, current_time: Time.current)
    course = role.teacher.course
    periods = course.periods.reject(&:archived?)
    ecosystem = course.ecosystem
    book = ecosystem.books.first

    core_page_ids = Tasks::Models::TaskPlan
      .select(:settings)
      .where(course: course)
      .flat_map(&:core_page_ids)
    chapter_uuid_page_uuids = Content::Models::Page
      .with_exercises
      .where(id: core_page_ids)
      .pluck(:parent_book_part_uuid, :uuid)
    chapter_uuids, page_uuids = chapter_uuid_page_uuids.transpose
    chapter_uuids = Set.new chapter_uuids
    page_uuids = Set.new page_uuids

    period_book_parts_by_period_id = Ratings::PeriodBookPart.where(
      period: periods, book_part_uuid: (chapter_uuids + page_uuids).to_a
    ).group_by(&:course_membership_period_id)

    outputs.teacher_guide = periods.map do |period|
      period_book_parts = period_book_parts_by_period_id[period.id] || []
      period_book_parts_by_book_part_uuid = period_book_parts.index_by(&:book_part_uuid)

      chapter_guides = book.chapters.map do |chapter|
        page_guides = chapter.pages.map do |page|
          next unless page_uuids.include? page.uuid
          page_period_book_part = period_book_parts_by_book_part_uuid[page.uuid] ||
                                  Ratings::PeriodBookPart.new(
            period: period,
            book_part_uuid: page.uuid,
            is_page: true
          )

          {
            title: page.title,
            book_location: page.book_location,
            student_count: page_period_book_part.num_students,
            questions_answered_count: page_period_book_part.num_results,
            clue: page_period_book_part.clue,
            page_ids: [ page.id ],
            first_worked_at: page_period_book_part.created_at,
            last_worked_at: page_period_book_part.updated_at
          }
        end.compact
        next if page_guides.empty?

        chapter_period_book_part = period_book_parts_by_book_part_uuid[chapter.uuid] ||
                                   Ratings::PeriodBookPart.new(
          period: period,
          book_part_uuid: chapter.uuid,
          is_page: false
        )

        {
          title: chapter.title,
          book_location: chapter.book_location,
          student_count: chapter_period_book_part.num_students,
          questions_answered_count: chapter_period_book_part.num_results,
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
