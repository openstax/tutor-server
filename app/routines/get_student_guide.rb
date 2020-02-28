class GetStudentGuide
  lev_routine express_output: :student_guide

  include ClueMerger

  protected

  def exec(role:, current_time: Time.current)
    if role.teacher_student?
      student = role.teacher_student
      student_ids_column = :teacher_student_ids
    else
      student = role.student
      student_ids_column = :student_ids
    end

    period = student.period
    course = period.course
    ecosystems = course.ecosystems
    ecosystem_ids = ecosystems.map(&:id)

    # Create an ordering of preferred ecosystems based on how recent they are
    index_by_ecosystem_id = {}
    ecosystem_ids.each_with_index do |ecosystem_id, index|
      index_by_ecosystem_id[ecosystem_id] = index
    end

    # Get cached Task stats, prioritizing the most recent ecosystem available for each one
    tc = Tasks::Models::TaskCache.arel_table
    task_caches = Tasks::Models::TaskCache
      .select(:tasks_task_id, :content_ecosystem_id, :task_type, :as_toc)
      .where(content_ecosystem_id: ecosystem_ids)
      .where("\"tasks_task_caches\".\"#{student_ids_column}\" && ARRAY[#{student.id}]")
      .where(tc[:opens_at].eq(nil).or tc[:opens_at].lteq(current_time))
      .where(withdrawn_at: nil)
      .sort_by { |task_cache| index_by_ecosystem_id[task_cache.content_ecosystem_id] }
      .uniq { |task_cache| task_cache.tasks_task_id }

    # Get cached Task stats by chapter
    chs = task_caches.flat_map do |task_cache|
      practice = task_cache.practice?

      task_cache.as_toc[:books].flat_map do |bk|
        bk[:chapters].select { |ch| ch[:has_exercises] }.map do |ch|
          pgs = ch[:pages].select { |pg| pg[:has_exercises] }.map do |pg|
            pg.merge practice: practice
          end

          ch.merge practice: practice, pages: pgs
        end
      end
    end

    # Create Biglearn Student CLUe requests
    pgs = chs.flat_map { |ch| ch[:pages] }
    bc_uuids = chs.map { |ch| ch[:tutor_uuid] } + pgs.flat_map do |pg|
      pg[:unmapped_tutor_uuids] || [ pg[:tutor_uuid] ]
    end
    biglearn_requests = bc_uuids.map do |book_container_uuid|
      { book_container_uuid: book_container_uuid, student: student }
    end

    # Get the Student CLUes from Biglearn
    biglearn_responses = OpenStax::Biglearn::Api.fetch_student_clues(biglearn_requests)
    biglearn_clue_by_book_container_uuid = biglearn_responses.map do |request, response|
      [ request[:book_container_uuid], response ]
    end.to_h

    # Get the preferred books and chapters
    preferred_ecosystem = ecosystems.first
    preferred_books = preferred_ecosystem.books
    book_title = preferred_books.map(&:title).uniq.sort.join('; ')

    preferred_chapters = preferred_books.flat_map(&:chapters)
    other_books = ecosystems[1..-1].map(&:books)
    other_chapters = other_books.map { |books| books.flat_map(&:chapters) }
    grouped_chapters = preferred_chapters.zip(*other_chapters)

    chs_by_tutor_uuid = chs.group_by { |ch| ch[:tutor_uuid] }

    # Merge the TaskCache ToCs and create the Student Performance Forecast
    chapter_guides = grouped_chapters.map do |chapter_group|
      chapters = chapter_group.compact
      chapter_tutor_uuids = chapters.map(&:tutor_uuid)
      chs = chs_by_tutor_uuid.values_at(*chapter_tutor_uuids).compact.flatten
      next if chs.empty?

      pgs = chs.flat_map { |ch| ch[:pages] }
      pgs_by_tutor_uuid = pgs.group_by { |pg| pg[:tutor_uuid] }

      preferred_chapter = chapters.first
      preferred_pages = preferred_chapter.pages
      other_pages = chapters[1..-1].map(&:pages)
      grouped_pages = preferred_pages.zip(*other_pages)

      page_guides = grouped_pages.map do |page_group|
        pages = page_group.compact
        page_tutor_uuids = pages.map(&:tutor_uuid)
        pgs = pgs_by_tutor_uuid.values_at(*page_tutor_uuids).compact.flatten
        next if pgs.empty?

        preferred_page = pages.first

        {
          title: preferred_page.title,
          book_location: preferred_page.book_location,
          student_count: 1,
          questions_answered_count: pgs.map { |pg| pg[:num_completed_exercises] }.sum,
          clue: merge_clues(pgs, biglearn_clue_by_book_container_uuid),
          page_ids: [ preferred_page.id ],
          first_worked_at: pgs.map { |pg| pg[:first_worked_at] }.compact.min,
          last_worked_at: pgs.map { |pg| pg[:last_worked_at] }.compact.max
        }
      end.compact

      {
        title: preferred_chapter.title,
        book_location: preferred_chapter.book_location,
        student_count: 1,
        questions_answered_count: page_guides.map { |guide| guide[:questions_answered_count] }.sum,
        clue: merge_clues(chs, biglearn_clue_by_book_container_uuid),
        page_ids: page_guides.map { |guide| guide[:page_ids] }.reduce([], :+),
        first_worked_at: chs.map { |ch| ch[:first_worked_at] }.compact.min,
        last_worked_at: chs.map { |ch| ch[:last_worked_at] }.compact.max,
        children: page_guides
      }
    end.compact

    outputs.student_guide = {
      period_id: period.id,
      title: book_title,
      page_ids: chapter_guides.map { |guide| guide[:page_ids] }.reduce([], :+),
      children: chapter_guides
    }
  end
end
