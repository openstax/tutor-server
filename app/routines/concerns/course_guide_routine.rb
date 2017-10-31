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
    student_ids = students.map(&:id)

    # Group students by their current period
    students_by_period_id = students.group_by { |student| student.period.id }

    # Get cached Task stats split into pages
    # The join on all_exercises_pool is used to exclude pages with no exercises (intro pages)
    tpc = Tasks::Models::TaskPageCache.arel_table
    cp = Content::Models::Pool.arel_table
    task_page_caches = Tasks::Models::TaskPageCache
      .select([
        :tasks_task_id,
        :course_membership_student_id,
        :content_mapped_page_id,
        :num_completed_exercises
      ])
      .joins(mapped_page: :all_exercises_pool)
      .where(course_membership_student_id: student_ids)
      .where(tpc[:opens_at].eq(nil).or tpc[:opens_at].lteq(current_time))
      .where(cp[:content_exercise_ids].not_eq([]))
    task_page_caches_by_student_id = task_page_caches.group_by(&:course_membership_student_id)

    # Get period and course information
    period_ids = students_by_period_id.keys
    period_by_period_id = CourseMembership::Models::Period
      .select([:id, :uuid, :course_profile_course_id])
      .where(id: period_ids)
      .index_by(&:id)

    # Get book titles
    course_ids = period_by_period_id.values.map(&:course_profile_course_id)
    book_title_by_course_id = CourseProfile::Models::Course
      .select(:id)
      .where(id: course_ids)
      .preload(ecosystems: :books)
      .map do |course|
      [course.id, course.ecosystems.first.books.map(&:title).join('; ')]
    end.to_h

    # Get mapped page uuids, titles and book_locations
    page_ids = task_page_caches.map(&:content_mapped_page_id)
    pages = Content::Models::Page
      .select([:id, :tutor_uuid, :title, :book_location, :content_chapter_id])
      .where(id: page_ids)
      .preload(chapter: { book: :ecosystem })
    chapters = pages.map(&:chapter).uniq

    # Get a list of practice task ids
    task_ids = task_page_caches.map(&:tasks_task_id)
    practice_task_types = Tasks::Models::Task.task_types.values_at(
      :chapter_practice, :page_practice, :mixed_practice, :practice_worst_topics
    )
    practice_task_ids = Tasks::Models::Task
      .where(id: task_ids, task_type: practice_task_types)
      .pluck(:id)

    # Create Biglearn Student/Teacher CLUe requests
    biglearn_requests = students_by_period_id.flat_map do |period_id, students|
      student_ids = students.map(&:id)
      task_page_caches = task_page_caches_by_student_id.values_at(*student_ids).compact.flatten
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

    # A page that has been assigned to any period of this course
    # will appear in the performance forecast for all periods
    pages_by_chapter = pages.group_by(&:chapter)

    # Create the Performance Forecast
    students_by_period_id.map do |period_id, students|
      student_ids = students.map(&:id)
      task_page_caches = task_page_caches_by_student_id.values_at(*student_ids).compact.flatten
      task_page_caches_by_page_id = task_page_caches.group_by(&:content_mapped_page_id)
      biglearn_clue_by_book_container_uuid =
        biglearn_clue_by_period_id_and_book_container_uuid[period_id] if type == :teacher

      chapter_guides = pages_by_chapter.map do |chapter, pages|
        page_guides = pages.map do |page|
          page_id = page.id
          task_page_caches = task_page_caches_by_page_id[page_id] || []
          student_count = task_page_caches.map(&:course_membership_student_id).uniq.size
          task_ids = task_page_caches.map(&:tasks_task_id)
          questions_answered_count = task_page_caches.map(&:num_completed_exercises).reduce(0, :+)
          practice_count = (practice_task_ids & task_ids).size
          clue = biglearn_clue_by_book_container_uuid[page.tutor_uuid]

          {
            title: page.title,
            book_location: page.book_location,
            student_count: student_count,
            questions_answered_count: questions_answered_count,
            practice_count: practice_count,
            clue: clue,
            page_ids: [ page_id ]
          }
        end

        page_ids = pages.map(&:id)
        task_page_caches = task_page_caches_by_page_id.values_at(*page_ids).compact.flatten
        student_count = task_page_caches.map(&:course_membership_student_id).uniq.size
        task_ids = task_page_caches.map(&:tasks_task_id)
        questions_answered_count = page_guides.map { |guide| guide[:questions_answered_count] }
                                              .reduce(0, :+)
        practice_count = (practice_task_ids & task_ids).size
        clue = biglearn_clue_by_book_container_uuid[chapter.tutor_uuid]
        page_ids = page_guides.map { |guide| guide[:page_ids] }.reduce([], :+)

        {
          title: chapter.title,
          book_location: chapter.book_location,
          student_count: student_count,
          questions_answered_count: questions_answered_count,
          practice_count: practice_count,
          clue: clue,
          page_ids: page_ids,
          children: page_guides
        }
      end

      period = period_by_period_id[period_id]
      course_id = period.course_profile_course_id
      book_title = book_title_by_course_id[course_id]
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
