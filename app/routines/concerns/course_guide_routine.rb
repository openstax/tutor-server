# Note: Not a real ActiveSupport::Concern but no reason it couldn't be
module CourseGuideRoutine

  protected

  def self.included(base)
    base.lev_routine express_output: :course_guide
  end

  def get_course_guide(students:, type:, current_time: Time.current)
    raise 'Course guide type must be either :student or :teacher' \
      unless [ :student, :teacher ].include? type

    # Preload each student's latest enrollment and period for the checks below
    students = [students].flatten
    ActiveRecord::Associations::Preloader.new.preload(students, latest_enrollment: :period)

    # Ignore dropped students and students in archived periods
    students = students.reject { |student| student.dropped? || student.period.archived? }
    return [] if students.empty?

    student_ids = students.map(&:id)

    # Group students by their current period
    students_by_period_id = students.group_by { |student| student.period.id }

    # Get period and course information
    period_ids = students_by_period_id.keys
    period_by_period_id = CourseMembership::Models::Period
      .select([:id, :uuid, :course_profile_course_id])
      .where(id: period_ids)
      .index_by(&:id)

    # Get the current course ecosystem
    course_ids = period_by_period_id.values.map(&:course_profile_course_id).uniq
    raise(
      NotImplementedError,
      'Performance Forecast currently can only be calculated on a single course'
    ) if course_ids.size > 1

    # Get all course ecosystems
    ecosystems = CourseProfile::Models::Course
      .select(:id)
      .preload(:ecosystems)
      .find_by(id: course_ids.first)
      .ecosystems
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
      .select([ :tasks_task_id, :content_ecosystem_id, :task_type, :student_ids, :as_toc ])
      .where(content_ecosystem_id: ecosystem_ids)
      .where("\"tasks_task_caches\".\"student_ids\" && ARRAY[#{student_ids.join(', ')}]")
      .where(tc[:opens_at].eq(nil).or tc[:opens_at].lteq(current_time))
      .sort_by { |task_cache| index_by_ecosystem_id[task_cache.content_ecosystem_id] }
      .uniq { |task_cache| task_cache.tasks_task_id }

    # Get mapped page and chapter UUIDs
    page_ids = task_caches.flat_map do |task_cache|
      task_cache.as_toc[:books].flat_map do |book|
        book[:chapters].flat_map do |chapter|
          chapter[:pages].reject { |page| page[:is_intro] }.map { |page| page[:id] }
        end
      end
    end
    pages = Content::Models::Page
      .select([:tutor_uuid, :content_chapter_id])
      .where(id: page_ids)
      .preload(chapter: { book: :ecosystem })
    chapters = pages.map(&:chapter).uniq

    # Get cached Task stats by student_ids
    task_caches_by_student_id = Hash.new { |hash, key| hash[key] = [] }
    task_caches.each do |task_cache|
      task_cache.student_ids.each do |student_id|
        task_caches_by_student_id[student_id] << task_cache
      end
    end

    # Create Biglearn Student/Teacher CLUe requests
    biglearn_requests = students_by_period_id.flat_map do |period_id, students|
      student_ids = students.map(&:id)
      task_caches = task_caches_by_student_id.values_at(*student_ids).compact.flatten
      book_containers = chapters + pages

      if type == :teacher
        period = period_by_period_id[period_id]

        book_containers.map do |book_container|
          { book_container: book_container, course_container: period }
        end
      else
        students.flat_map do |student|
          book_containers.map do |book_container|
            { book_container: book_container, student: student }
          end
        end
      end
    end

    # Get the Student/Teacher CLUes from Biglearn
    if type == :teacher
      biglearn_responses = OpenStax::Biglearn::Api.fetch_teacher_clues(biglearn_requests)
      biglearn_clue_by_period_id_and_book_container_uuid = Hash.new { |hash, key| hash[key] = {} }
      biglearn_responses.each do |request, resp|
        period_id = request[:course_container].id
        book_container_uuid = request[:book_container].tutor_uuid
        biglearn_clue_by_period_id_and_book_container_uuid[period_id][book_container_uuid] = resp
      end
    else
      biglearn_responses = OpenStax::Biglearn::Api.fetch_student_clues(biglearn_requests)
      biglearn_clue_by_book_container_uuid = biglearn_responses.map do |request, response|
        [ request[:book_container].tutor_uuid, response ]
      end.to_h
    end

    # Merge the TaskCache ToCs and create the Performance Forecast
    students_by_period_id.map do |period_id, students|
      student_ids = students.map(&:id)
      biglearn_clue_by_book_container_uuid =
        biglearn_clue_by_period_id_and_book_container_uuid[period_id] if type == :teacher
      task_caches = task_caches_by_student_id.values_at(*student_ids).flatten

      chs = task_caches.flat_map do |task_cache|
        task_cache.as_toc[:books].flat_map do |bk|
          bk[:chapters].map do |ch|
            ch.merge student_ids: task_cache.student_ids, practice: task_cache.practice?
          end
        end
      end

      chapter_guides = chs.group_by { |ch| ch[:book_location] }.sort.map do |book_location, chs|
        pgs = chs.flat_map do |ch|
          ch[:pages].reject { |pg| pg[:is_intro] }
                    .map { |pg| pg.merge ch.slice(:student_ids, :practice) }
        end

        page_guides = pgs.group_by { |pg| pg[:book_location] }.sort.map do |book_location, pgs|
          preferred_pg = pgs.first
          student_count = pgs.flat_map { |pg| pg[:student_ids] }.uniq.size
          questions_answered_count = pgs.map { |pg| pg[:num_completed_exercises] }.reduce(0, :+)
          practice_count = pgs.count { |pg| pg[:practice] }
          clue = biglearn_clue_by_book_container_uuid[preferred_pg[:tutor_uuid]]

          {
            title: preferred_pg[:title],
            book_location: book_location,
            student_count: student_count,
            questions_answered_count: questions_answered_count,
            practice_count: practice_count,
            clue: clue,
            page_ids: [ preferred_pg[:id] ]
          }
        end

        preferred_ch = chs.first
        student_count = chs.flat_map { |ch| ch[:student_ids] }.uniq.size
        questions_answered_count = page_guides.map { |guide| guide[:questions_answered_count] }
                                              .reduce(0, :+)
        practice_count = chs.count { |ch| ch[:practice] }
        clue = biglearn_clue_by_book_container_uuid[preferred_ch[:tutor_uuid]]
        page_ids = page_guides.map { |guide| guide[:page_ids] }.reduce([], :+)

        {
          title: preferred_ch[:title],
          book_location: book_location,
          student_count: student_count,
          questions_answered_count: questions_answered_count,
          practice_count: practice_count,
          clue: clue,
          page_ids: page_ids,
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
