# Updates the TaskCaches, used by the Trouble Flag, Quick Look and Performance Forecast
# Tasks not assigned to a student (preview tasks) are ignored
class Tasks::UpdateTaskCaches
  lev_routine

  uses_routine GetCourseEcosystemsMap, as: :get_course_ecosystems_map

  protected

  def exec(tasks:)
    tasks = [tasks].flatten
    ActiveRecord::Associations::Preloader.new.preload tasks, :time_zone
    tasks_by_id = tasks.index_by(&:id)
    task_ids = tasks_by_id.keys

    # Get student and course IDs
    student_ids_by_task_id = Hash.new { |hash, key| hash[key] = [] }
    task_ids_by_course_id = Hash.new { |hash, key| hash[key] = [] }
    CourseMembership::Models::Student.joins(role: :taskings)
                                     .where(role: { taskings: { tasks_task_id: task_ids } })
                                     .pluck(:id, :tasks_task_id, :course_profile_course_id)
                                     .each do |id, task_id, course_id|
      student_ids_by_task_id[task_id] << id
      task_ids_by_course_id[course_id] << task_id
    end

    # Get TaskedExercises by task_id and page_id for each given task
    tasked_exercises_by_task_id_and_page_id = Hash.new do |hash, key|
      hash[key] = Hash.new { |hash, key| hash[key] = [] }
    end
    Tasks::Models::TaskedExercise
      .select([
        :content_exercise_id,
        :free_response,
        :answer_id,
        :correct_answer_id,
        '"content_exercises"."uuid"',
        '"tasks_task_steps"."first_completed_at" IS NOT NULL AS "completed"',
        '"tasks_task_steps"."tasks_task_id"',
        '"tasks_task_steps"."content_page_id"',
        '"tasks_task_steps"."number"'
      ])
      .joins(:exercise, :task_step)
      .where(task_step: { tasks_task_id: task_ids })
      .where('"tasks_task_steps"."content_page_id" IS NOT NULL')
      .order('"tasks_task_steps"."number"')
      .each do |tasked_exercise|
      task_id = tasked_exercise.tasks_task_id
      page_id = tasked_exercise.content_page_id
      tasked_exercises_by_task_id_and_page_id[task_id][page_id] << tasked_exercise
    end

    # Get the number of TaskedPlaceholders by task_id and page_id for each given task
    # Don't include placeholders whose page is currently unknown (NULL content_page_id)
    num_tasked_placeholders_by_task_id_and_page_id = Hash.new { |hash, key| hash[key] = Hash.new 0 }
    Tasks::Models::TaskedPlaceholder
      .joins(:task_step)
      .where(task_step: { tasks_task_id: task_ids })
      .where('"tasks_task_steps"."content_page_id" IS NOT NULL')
      .group(task_step: [ :tasks_task_id, :content_page_id ])
      .count
      .each do |(task_id, page_id), num_tasked_placeholders|
      num_tasked_placeholders_by_task_id_and_page_id[task_id][page_id] = num_tasked_placeholders
    end

    # Get all relevant pages
    page_ids = (
      tasked_exercises_by_task_id_and_page_id.values +
      num_tasked_placeholders_by_task_id_and_page_id.values
    ).flat_map(&:keys).uniq
    pages_by_id = Content::Models::Page
      .select([ :id, :uuid, :tutor_uuid, :title, :book_location, :content_chapter_id ])
      .where(id: page_ids)
      .map { |page| Content::Page.new strategy: page.wrap }
      .index_by(&:id)

    # Get all relevant courses
    course_ids = task_ids_by_course_id.keys
    courses = CourseProfile::Models::Course.select(:id).where(id: course_ids).preload(:ecosystems)

    # Cache results per task for Quick Look and Performance Forecast
    # Pages are mapped to the Course's most recent ecosystem
    task_caches = courses.flat_map do |course|
      task_ids = task_ids_by_course_id[course.id]
      ecosystem_map = run(:get_course_ecosystems_map, course: course).outputs.ecosystems_map
      page_ids = (
        tasked_exercises_by_task_id_and_page_id.values_at(*task_ids) +
        num_tasked_placeholders_by_task_id_and_page_id.values_at(*task_ids)
      ).flat_map(&:keys).uniq
      pages = pages_by_id.values_at(*page_ids)
      page_to_page_map = ecosystem_map.map_pages_to_pages pages: pages

      pages_by_mapped_book_chapter_and_page = Hash.new do |hash, key|
        hash[key] = Hash.new { |hash, key| hash[key] = Hash.new { |hash, key| hash[key] = [] } }
      end
      mapped_pages = page_to_page_map.values.compact
      unmapped_pages = page_to_page_map.select { |page, mapped_page| mapped_page.nil? }
                                       .map { |page, mapped_page| page.to_model }
      pages_to_preload = (mapped_pages + unmapped_pages).map(&:to_model)
      ActiveRecord::Associations::Preloader.new.preload pages_to_preload, chapter: :book
      page_to_page_map.each do |page, mapped_page|
        mapped_page ||= page
        chapter = mapped_page.chapter
        book = chapter.book
        pages_by_mapped_book_chapter_and_page[book][chapter][mapped_page] << page
      end

      task_ids.map do |task_id|
        task = tasks_by_id[task_id]
        tasked_exercises_by_page_id = tasked_exercises_by_task_id_and_page_id[task_id]
        num_tasked_placeholders_by_page_id = num_tasked_placeholders_by_task_id_and_page_id[task_id]
        student_ids = student_ids_by_task_id[task_id]

        books_array = pages_by_mapped_book_chapter_and_page
          .map do |mapped_book, pages_by_mapped_chapter_and_page|
          chapters_array = pages_by_mapped_chapter_and_page
            .map do |mapped_chapter, pages_by_mapped_page|
            pages_array = pages_by_mapped_page.map do |mapped_page, pages|
              page_ids = pages.map(&:id)
              tasked_exercises = tasked_exercises_by_page_id.values_at(*page_ids).flatten
              num_tasked_placeholders = num_tasked_placeholders_by_page_id.values_at(*page_ids)
                                                                          .reduce(0, :+)
              next if tasked_exercises.empty? && num_tasked_placeholders == 0

              exercises_array = tasked_exercises.map do |tasked_exercise|
                {
                  id: tasked_exercise.content_exercise_id,
                  uuid: tasked_exercise.uuid,
                  step_number: tasked_exercise.number,
                  free_response: tasked_exercise.free_response,
                  answer_id: tasked_exercise.answer_id,
                  completed: tasked_exercise.completed,
                  correct: tasked_exercise.is_correct?
                }
              end

              # No need to parse the entire page content,
              # since the title alone determines if a page is an intro page
              parser = OpenStax::Cnx::V1::Page.new(title: mapped_page.title)
              {
                id: mapped_page.id,
                tutor_uuid: mapped_page.tutor_uuid,
                title: mapped_page.title,
                book_location: mapped_page.book_location,
                is_intro: parser.is_intro?,
                num_assigned_exercises: exercises_array.size,
                num_completed_exercises: exercises_array.count { |exercise| exercise[:completed] },
                num_correct_exercises: exercises_array.count { |exercise| exercise[:correct] },
                num_assigned_placeholders: num_tasked_placeholders,
                exercises: exercises_array
              }
            end.compact.sort_by { |page| page[:book_location] }
            next if pages_array.empty?

            {
              id: mapped_chapter.id,
              tutor_uuid: mapped_chapter.tutor_uuid,
              title: mapped_chapter.title,
              book_location: mapped_chapter.book_location,
              num_assigned_exercises: pages_array.map { |page| page[:num_assigned_exercises] }
                                                 .reduce(0, :+),
              num_completed_exercises: pages_array.map { |page| page[:num_completed_exercises] }
                                                  .reduce(0, :+),
              num_correct_exercises: pages_array.map { |page| page[:num_correct_exercises] }
                                                .reduce(0, :+),
              num_assigned_placeholders: pages_array.map { |page| page[:num_assigned_placeholders] }
                                                    .reduce(0, :+),
              pages: pages_array
            }
          end.compact.sort_by { |chapter| chapter[:book_location] }
          next if chapters_array.empty?

          {
            id: mapped_book.id,
            tutor_uuid: mapped_book.tutor_uuid,
            title: mapped_book.title,
            num_assigned_exercises: chapters_array.map { |ch| ch[:num_assigned_exercises] }
                                                  .reduce(0, :+),
            num_completed_exercises: chapters_array.map { |ch| ch[:num_completed_exercises] }
                                                   .reduce(0, :+),
            num_correct_exercises: chapters_array.map { |ch| ch[:num_correct_exercises] }
                                                 .reduce(0, :+),
            num_assigned_placeholders: chapters_array.map { |ch| ch[:num_assigned_placeholders] }
                                                     .reduce(0, :+),
            chapters: chapters_array
          }
        end.compact.sort_by { |book| book[:title] }

        toc = { books: books_array }
        Tasks::Models::TaskCache.new(
          tasks_task_id: task_id,
          content_ecosystem_id: ecosystem_map.to_ecosystem.id,
          task_type: task.task_type,
          opens_at: task.opens_at,
          due_at: task.due_at,
          feedback_at: task.feedback_at,
          student_ids: student_ids,
          as_toc: toc
        )
      end
    end

    # Update the TaskCaches
    Tasks::Models::TaskCache.import task_caches, validate: false, on_duplicate_key_update: {
      conflict_target: [ :tasks_task_id, :content_ecosystem_id ],
      columns: [ :opens_at, :due_at, :feedback_at, :student_ids, :as_toc ]
    }
  end
end
