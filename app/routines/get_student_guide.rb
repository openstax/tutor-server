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

    chapter_uuids_by_page_uuid = Hash.new { |hash, key| hash[key] = [] }
    Content::Models::Page
      .with_exercises
      .where(id: core_page_ids)
      .pluck(:uuid, :parent_book_part_uuid)
      .each do |page_uuid, chapter_uuid|
      chapter_uuids_by_page_uuid[page_uuid] << chapter_uuid
    end
    page_uuids = Set.new chapter_uuids_by_page_uuid.keys
    chapter_uuids = Set.new chapter_uuids_by_page_uuid.values.flatten

    role_book_parts_by_book_part_uuid = Ratings::RoleBookPart.where(
      role: role, book_part_uuid: (chapter_uuids + page_uuids).to_a
    ).index_by(&:book_part_uuid)

    chapter_guides = book.chapters.map do |chapter|
      page_guides = chapter.pages.map do |page|
        next unless page_uuids.include? page.uuid
        page_role_book_part = role_book_parts_by_book_part_uuid[page.uuid] ||
                              Ratings::RoleBookPart.new(
          role: role,
          book_part_uuid: page.uuid,
          is_page: true
        )

        {
          title: page.title,
          book_location: page.book_location,
          student_count: 1,
          questions_answered_count: page_role_book_part.num_results,
          clue: page_role_book_part.clue,
          page_ids: [ page.id ],
          first_worked_at: page_role_book_part.created_at,
          last_worked_at: page_role_book_part.updated_at
        }
      end.compact
      next if page_guides.empty?

      chapter_uuids = (
        [ chapter.uuid ] + chapter_uuids_by_page_uuid.values_at(*chapter.pages.map(&:uuid)).flatten
      ).uniq

      chapter_role_book_parts = role_book_parts_by_book_part_uuid.values_at(*chapter_uuids).compact

      real_clue_book_parts = chapter_role_book_parts.select do |chapter_role_book_part|
        chapter_role_book_part.clue['is_real']
      end
      if real_clue_book_parts.empty?
        clue = {
          minimum: 0.0,
          most_likely: 0.5,
          maximum: 1.0,
          is_real: false
        }
      else
        most_likely = real_clue_book_parts.sum(0.0) do |chapter_role_book_part|
          chapter_role_book_part.clue['most_likely'] * chapter_role_book_part.num_results
        end/real_clue_book_parts.sum(0, &:num_results)

        clue = {
          minimum: 0.0,
          most_likely: most_likely,
          maximum: 1.0,
          is_real: true
        }
      end

      {
        title: chapter.title,
        book_location: chapter.book_location,
        student_count: 1,
        questions_answered_count: chapter_role_book_parts.sum(0, &:num_results),
        clue: clue,
        page_ids: page_guides.map { |guide| guide[:page_ids] }.reduce([], :+),
        first_worked_at: chapter_role_book_parts.map(&:created_at).min,
        last_worked_at: chapter_role_book_parts.map(&:updated_at).max,
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
