class GetStudentGuide

  lev_routine express_output: :student_guide

  protected

  def exec(role:, current_time: Time.current)
    student = role.student
    period = student.period
    course = period.course
    ecosystems = course.ecosystems
    ecosystem_ids = ecosystems.map(&:id)

    # Create an ordering of preferred ecosystems based on how recent they are
    index_by_ecosystem_id = {}
    ecosystem_ids.each_with_index do |ecosystem_id, index|
      index_by_ecosystem_id[ecosystem_id] = index
    end

    # Get the preferred book title (from the most recent ecosystem)
    preferred_books = ecosystems.first.books
    book_title = preferred_books.map(&:title).uniq.sort.join('; ')

    # Get cached Task stats, prioritizing the most recent ecosystem available for each one
    tc = Tasks::Models::TaskCache.arel_table
    task_caches = Tasks::Models::TaskCache
      .select([ :tasks_task_id, :content_ecosystem_id, :task_type, :as_toc ])
      .where(content_ecosystem_id: ecosystem_ids)
      .where("\"tasks_task_caches\".\"student_ids\" @> ARRAY[#{student.id}]")
      .where(tc[:opens_at].eq(nil).or tc[:opens_at].lteq(current_time))
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

    # Get mapped page and chapter UUIDs
    page_ids = chs.flat_map { |ch| ch[:pages].map { |pg| pg[:id] } }
    pages = Content::Models::Page
      .select([:tutor_uuid, :content_chapter_id])
      .where(id: page_ids)
      .preload(chapter: { book: :ecosystem })
    chapters = pages.map(&:chapter).uniq
    book_containers = chapters + pages

    # Create Biglearn Student CLUe requests
    biglearn_requests = book_containers.map do |book_container|
      { book_container: book_container, student: student }
    end

    # Get the Student CLUes from Biglearn
    biglearn_responses = OpenStax::Biglearn::Api.fetch_student_clues(biglearn_requests)
    biglearn_clue_by_book_container_uuid = biglearn_responses.map do |request, response|
      [ request[:book_container].tutor_uuid, response ]
    end.to_h

    # Merge the TaskCache ToCs and create the Student Performance Forecast
    chapter_guides = chs.group_by { |ch| ch[:book_location] }.sort.map do |book_location, chs|
      pgs = chs.flat_map { |ch| ch[:pages] }

      page_guides = pgs.group_by { |pg| pg[:book_location] }.sort.map do |book_location, pgs|
        preferred_pg = pgs.first
        questions_answered_count = pgs.map { |pg| pg[:num_completed_exercises] }.reduce(0, :+)
        clue = biglearn_clue_by_book_container_uuid[preferred_pg[:tutor_uuid]]

        {
          title: preferred_pg[:title],
          book_location: book_location,
          baked_book_location: preferred_pg[:baked_book_location],
          student_count: 1,
          questions_answered_count: questions_answered_count,
          clue: clue,
          page_ids: [ preferred_pg[:id] ]
        }
      end

      preferred_ch = chs.first
      questions_answered_count = page_guides.map { |guide| guide[:questions_answered_count] }
                                            .reduce(0, :+)
      clue = biglearn_clue_by_book_container_uuid[preferred_ch[:tutor_uuid]]
      page_ids = page_guides.map { |guide| guide[:page_ids] }.reduce([], :+)

      {
        title: preferred_ch[:title],
        book_location: book_location,
        baked_book_location: preferred_ch[:baked_book_location],
        student_count: 1,
        questions_answered_count: questions_answered_count,
        clue: clue,
        page_ids: page_ids,
        children: page_guides
      }
    end

    page_ids = chapter_guides.map { |guide| guide[:page_ids] }.reduce([], :+)
    outputs.student_guide = {
      period_id: period.id,
      title: book_title,
      page_ids: page_ids,
      children: chapter_guides
    }
  end

end
