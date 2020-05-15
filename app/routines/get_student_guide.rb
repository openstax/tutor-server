class GetStudentGuide
  lev_routine express_output: :student_guide

  protected

  def exec(role:, current_time: Time.current)
    period = role.course_member.period
    course = period.course
    ecosystem = course.ecosystem
    book = ecosystem.books.first

    tt = Tasks::Models::Task.arel_table
    tasks = Tasks::Models::Task
      .joins(:taskings)
      .where(taskings: { entity_role_id: role.id })
    core_page_ids = tasks.where(tt[:completed_steps_count].eq(tt[:steps_count])).or(
      tasks.where.not(due_at_ntz: nil).where(
        <<~WHERE_SQL
          TIMEZONE('#{course.timezone}', "tasks_tasks"."due_at_ntz") <= '#{current_time.to_s(:db)}'
        WHERE_SQL
      )
    ).pluck(:core_page_ids).flatten.uniq
    chapter_uuid_page_uuids = Content::Models::Page
      .where(id: core_page_ids)
      .pluck(:parent_book_part_uuid, :uuid)
    chapter_uuids, page_uuids = chapter_uuid_page_uuids.transpose
    chapter_uuids = Set.new chapter_uuids
    page_uuids = Set.new page_uuids

    role_book_parts_by_book_part_uuid = Ratings::RoleBookPart.where(
      role: role, book_part_uuid: (chapter_uuids + page_uuids).to_a
    ).index_by(&:book_part_uuid)

    chapter_guides = book.chapters.map do |chapter|
      next unless chapter_uuids.include? chapter.uuid
      chapter_role_book_part = role_book_parts_by_book_part_uuid[chapter.uuid] ||
                               Ratings::RoleBookPart.new(
        tasked_exercise_ids: [],
        clue: {
          minimum: 0.0,
          most_likely: 0.5,
          maximum: 1.0,
          is_real: false
        }
      )

      page_guides = chapter.pages.map do |page|
        next unless page_uuids.include? page.uuid
        page_role_book_part = role_book_parts_by_book_part_uuid[page.uuid] ||
                              Ratings::RoleBookPart.new(
          tasked_exercise_ids: [],
          clue: {
            minimum: 0.0,
            most_likely: 0.5,
            maximum: 1.0,
            is_real: false
          }
        )

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
