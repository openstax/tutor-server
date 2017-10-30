# Note: Not a real ActiveSupport::Concern but no reason it couldn't be
module CourseGuideRoutine

  protected

  def self.included(base)
    base.lev_routine express_output: :course_guide
  end

  def get_course_guide(students:, type:)
    raise 'Course guide type must be either :student or :teacher' \
      unless [ :student, :teacher ].include? type

    students = [students].flatten
    student_ids = students.map(&:id)

    # Group students by their current period
    ActiveRecord::Associations::Preloader.new.preload(students, :latest_enrollment)
    students_by_period_id = students.group_by do |student|
      student.latest_enrollment.course_membership_period_id
    end

    # Get cached Task stats split into pages
    task_page_caches = Tasks::Models::TaskPageCache
      .select([
        :tasks_task_id,
        :course_membership_student_id,
        :content_mapped_page_id,
        :num_completed_exercises
      ])
      .where(course_membership_student_id: student_ids)
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

      if type == :student
        students.flat_map do |student|
          book_containers.map do |book_container|
            { book_container: book_container, student: student }
          end
        end
      else
        period = period_by_period_id[period_id]

        book_containers.map do |book_container|
          { book_container: book_container, course_container: period }
        end
      end
    end

    # Get the Student/Teacher CLUes from Biglearn
    biglearn_responses = if type == :student
      OpenStax::Biglearn::Api.fetch_student_clues(biglearn_requests)
    else
      OpenStax::Biglearn::Api.fetch_teacher_clues(biglearn_requests)
    end
    biglearn_clue_by_book_container_uuid = biglearn_responses.map do |request, response|
      [ request[:book_container].tutor_uuid, response ]
    end.to_h

    # A page that has been assigned to any period of this course
    # will appear in the performance forecast for all periods
    pages_by_chapter = pages.group_by(&:chapter)

    # Create the Performance Forecast
    students_by_period_id.map do |period_id, students|
      student_ids = students.map(&:id)
      task_page_caches = task_page_caches_by_student_id.values_at(*student_ids).compact.flatten
      task_page_caches_by_page_id = task_page_caches.group_by(&:content_mapped_page_id)

      period = period_by_period_id[period_id]
      course_id = period.course_profile_course_id
      book_title = book_title_by_course_id[course_id]

      chapter_guides = pages_by_chapter.map do |chapter, pages|
        page_ids = pages.map(&:id)
        task_page_caches = task_page_caches_by_page_id.values_at(*page_ids).compact.flatten
        student_count = task_page_caches.map(&:course_membership_student_id).uniq.size
        task_ids = task_page_caches.map(&:tasks_task_id)
        practice_count = (practice_task_ids & task_ids).size
        clue = biglearn_clue_by_book_container_uuid[chapter.tutor_uuid]

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

        questions_answered_count = page_guides.map { |guide| guide[:questions_answered_count] }
                                              .reduce(0, :+)
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
