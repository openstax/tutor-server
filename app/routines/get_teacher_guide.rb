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
    course.ecosystems.each_with_index do |ecosystem, index|
      index_by_ecosystem_id[ecosystem.id] = index
    end

    # Get the preferred book title (from the most recent ecosystem)
    preferred_books = ecosystems.first.books
    book_title = preferred_books.map(&:title).uniq.sort.join('; ')

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

    # Get mapped page and chapter UUIDs
    page_ids = chs_by_period_id.values.flatten.flat_map do |ch|
      ch[:pages].map { |page| page[:id] }
    end
    pages = Content::Models::Page
      .select([:tutor_uuid, :content_chapter_id])
      .where(id: page_ids)
      .preload(chapter: { book: :ecosystem })
    chapters = pages.map(&:chapter).uniq
    book_containers = chapters + pages

    # Create Biglearn Teacher CLUe requests
    biglearn_requests = periods.flat_map do |period|
      book_containers.map do |book_container|
        { book_container: book_container, course_container: period }
      end
    end

    # Get the Teacher CLUes from Biglearn
    biglearn_responses = OpenStax::Biglearn::Api.fetch_teacher_clues(biglearn_requests)
    biglearn_clue_by_period_id_and_book_container_uuid = Hash.new { |hash, key| hash[key] = {} }
    biglearn_responses.each do |request, response|
      period_id = request[:course_container].id
      book_container_uuid = request[:book_container].tutor_uuid
      biglearn_clue_by_period_id_and_book_container_uuid[period_id][book_container_uuid] = response
    end

    # Merge the PeriodCache ToCs and create the Performance Forecast
    outputs.teacher_guide = periods.map do |period|
      period_id = period.id
      chs = chs_by_period_id[period_id]
      biglearn_clue_by_book_container_uuid =
        biglearn_clue_by_period_id_and_book_container_uuid[period_id]

      chapter_guides = chs.group_by { |ch| ch[:book_location] }.sort.map do |book_location, chs|
        pgs = chs.flat_map { |ch| ch[:pages] }

        page_guides = pgs.group_by { |pg| pg[:book_location] }.sort.map do |book_location, pgs|
          preferred_pg = pgs.first

          {
            title: preferred_pg[:title],
            book_location: book_location,
            baked_book_location: preferred_pg[:baked_book_location],
            student_count: pgs.flat_map { |pg| pg[:student_ids] }.uniq.size,
            questions_answered_count: pgs.map { |pg| pg[:num_completed_exercises] }.sum,
            clue: merge_clues(pgs, biglearn_clue_by_book_container_uuid),
            page_ids: [ preferred_pg[:id] ]
          }
        end

        preferred_ch = chs.first
        questions_answered_count = page_guides.map { |guide| guide[:questions_answered_count] }.sum

        {
          title: preferred_ch[:title],
          book_location: book_location,
          baked_book_location: preferred_ch[:baked_book_location],
          student_count: chs.flat_map { |ch| ch[:student_ids] }.uniq.size,
          questions_answered_count: questions_answered_count,
          clue: merge_clues(chs, biglearn_clue_by_book_container_uuid),
          page_ids: page_guides.map { |guide| guide[:page_ids] }.reduce([], :+),
          children: page_guides
        }
      end

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
