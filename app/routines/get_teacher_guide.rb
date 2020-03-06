class GetTeacherGuide
  lev_routine express_output: :teacher_guide

  include ClueMerger

  protected

  def exec(role:, current_time: Time.current)
    course = role.teacher.course
    periods = course.periods.reject(&:archived?)
    if periods.empty?
      outputs.teacher_guide = []
      return
    end

    ecosystems = course.ecosystems
    ecosystem_ids = ecosystems.map(&:id)
    period_ids = periods.map(&:id)

    # Create an ordering of preferred ecosystems based on how recent they are
    index_by_ecosystem_id = {}
    ecosystems.each_with_index do |ecosystem, index|
      index_by_ecosystem_id[ecosystem.id] = index
    end

    # Get cached TaskPlan stats, prioritizing the most recent ecosystem available for each one
    pc = Tasks::Models::PeriodCache.arel_table
    period_caches = Tasks::Models::PeriodCache
      .select([
        :course_membership_period_id,
        :content_ecosystem_id,
        :tasks_task_plan_id,
        :student_ids,
        :as_toc
      ])
      .where(content_ecosystem_id: ecosystem_ids, course_membership_period_id: period_ids)
      .where(pc[:opens_at].eq(nil).or pc[:opens_at].lteq(current_time))
      .sort_by { |period_cache| index_by_ecosystem_id[period_cache.content_ecosystem_id] }
      .uniq do |period_cache|
        [ period_cache.course_membership_period_id, period_cache.tasks_task_plan_id ]
      end

    # Get cached Task stats by chapter by period_id
    chs_by_period_id = Hash.new { |hash, key| hash[key] = [] }
    period_caches.each do |period_cache|
      student_ids = period_cache.student_ids
      practice = period_cache.practice?

      chs_by_period_id[period_cache.course_membership_period_id].concat(
        period_cache.as_toc[:books].flat_map do |bk|
          bk[:chapters].select { |ch| ch[:has_exercises] }.map do |ch|
            pgs = ch[:pages].select { |pg| pg[:has_exercises] }.map do |pg|
              pg.merge student_ids: student_ids, practice: practice
            end

            ch.merge student_ids: student_ids, practice: practice, pages: pgs
          end
        end
      )
    end

    # Create Biglearn Teacher CLUe requests
    biglearn_requests = periods.flat_map do |period|
      chs = chs_by_period_id[period.id]
      pgs = chs.flat_map { |ch| ch[:pages] }
      bc_uuids = chs.map { |ch| ch[:tutor_uuid] }.uniq + pgs.flat_map do |pg|
        (pg[:unmapped_tutor_uuids] || []) + [ pg[:tutor_uuid] ]
      end.uniq
      bc_uuids.map do |book_container_uuid|
        { book_container_uuid: book_container_uuid, course_container: period }
      end
    end

    # Get the Teacher CLUes from Biglearn
    biglearn_responses = OpenStax::Biglearn::Api.fetch_teacher_clues(biglearn_requests)
    biglearn_clue_by_period_id_and_book_container_uuid = Hash.new { |hash, key| hash[key] = {} }
    biglearn_responses.each do |request, response|
      period_id = request[:course_container].id
      book_container_uuid = request[:book_container_uuid]
      biglearn_clue_by_period_id_and_book_container_uuid[period_id][book_container_uuid] = response
    end

    # Get the preferred books and chapters
    preferred_ecosystem = ecosystems.first
    preferred_books = preferred_ecosystem.books
    book_title = preferred_books.map(&:title).uniq.sort.join('; ')

    preferred_chapters = preferred_books.flat_map(&:chapters)
    other_books = ecosystems[1..-1].map(&:books)
    other_chapters = other_books.map { |books| books.flat_map(&:chapters) }
    grouped_chapters = preferred_chapters.zip(*other_chapters)

    # Merge the PeriodCache ToCs and create the Performance Forecast
    outputs.teacher_guide = periods.map do |period|
      period_id = period.id
      chs = chs_by_period_id[period_id]
      chs_by_tutor_uuid = chs.group_by { |ch| ch[:tutor_uuid] }
      biglearn_clue_by_book_container_uuid =
        biglearn_clue_by_period_id_and_book_container_uuid[period_id]

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
            student_count: pgs.flat_map { |pg| pg[:student_ids] }.uniq.size,
            questions_answered_count: pgs.map { |pg| pg[:num_completed_exercises] }.sum,
            clue: merge_clues(pgs, biglearn_clue_by_book_container_uuid),
            page_ids: [ preferred_page.id ]
          }
        end.compact

        questions_answered_count = page_guides.map { |guide| guide[:questions_answered_count] }.sum

        {
          title: preferred_chapter.title,
          book_location: preferred_chapter.book_location,
          student_count: chs.flat_map { |ch| ch[:student_ids] }.uniq.size,
          questions_answered_count: questions_answered_count,
          clue: merge_clues(chs, biglearn_clue_by_book_container_uuid),
          page_ids: page_guides.map { |guide| guide[:page_ids] }.reduce([], :+),
          children: page_guides
        }
      end.compact

      page_ids = chapter_guides.map { |guide| guide[:page_ids] }.reduce([], :+)
      {
        period_id: period_id,
        title: book_title,
        page_ids: page_ids,
        children: chapter_guides
      }
    end
  end
end
