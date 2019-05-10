# Updates the TaskCaches, used by the Quick Look and Student Performance Forecast
# Tasks not assigned to a student (preview tasks) are ignored
class Tasks::UpdateTaskCaches
  lev_routine active_job_enqueue_options: { queue: :low_priority }, transaction: :read_committed

  uses_routine GetCourseEcosystemsMap, as: :get_course_ecosystems_map

  protected

  def exec(task_ids:, update_step_counts: false, queue: 'low_priority')
    ScoutHelper.ignore!(0.995)

    task_ids = [task_ids].flatten

    # Attempt to lock the tasks; Skip tasks already locked by someone else
    tasks = Tasks::Models::Task
      .where(id: task_ids)
      .lock('FOR NO KEY UPDATE SKIP LOCKED')
      .preload(:ecosystem, :time_zone, taskings: { role: { student: :period } })
      .to_a
    tasks_by_id = tasks.index_by(&:id)
    locked_task_ids = tasks_by_id.keys

    # Requeue tasks that exist but we couldn't lock
    skipped_task_ids = task_ids - locked_task_ids
    existing_skipped_task_ids = Tasks::Models::Task.where(id: skipped_task_ids).pluck(:id)
    self.class.perform_later(task_ids: existing_skipped_task_ids) \
      unless existing_skipped_task_ids.empty?
    task_ids = locked_task_ids

    # Stop if we couldn't lock any tasks at all
    return if task_ids.empty?

    # Get TaskSteps for each given task
    task_steps = Tasks::Models::TaskStep
      .select([
        :tasks_task_id,
        :number,
        :first_completed_at,
        :last_completed_at,
        :content_page_id,
        :group_type,
        :tasked_type,
        :tasked_id
      ])
      .where(tasks_task_id: task_ids)
      .order(:number)
      .to_a

    # Preload all TaskedExercises
    exercise_steps = task_steps.select(&:exercise?)
    ActiveRecord::Associations::Preloader.new.preload exercise_steps, :tasked

    # Preload all TaskedPlaceholders
    placeholder_steps = task_steps.select(&:placeholder?)
    ActiveRecord::Associations::Preloader.new.preload placeholder_steps, :tasked

    # Group TaskSteps by task_id and page_id
    task_steps_by_task_id_and_page_id = Hash.new do |hash, key|
      hash[key] = Hash.new { |hash, key| hash[key] = [] }
    end
    task_steps.each do |task_step|
      task_id = task_step.tasks_task_id
      page_id = task_step.content_page_id
      task_steps_by_task_id_and_page_id[task_id][page_id] << task_step
    end

    if update_step_counts
      tasks = tasks.map do |task|
        task_steps = task_steps_by_task_id_and_page_id[task.id].values.flatten
        task.update_step_counts steps: task_steps
      end

      # Update the Task cache columns (scores cache)
      Tasks::Models::Task.import tasks, validate: false, on_duplicate_key_update: {
        conflict_target: [ :id ], columns: Tasks::Models::Task::CACHE_COLUMNS
      }
    end

    # Get student and course IDs
    students = CourseMembership::Models::Student
      .select([
        :id,
        :course_profile_course_id,
        :course_membership_period_id,
        '"tasks_taskings"."tasks_task_id"',
        '"user_profiles"."account_id"'
      ])
      .joins(role: [ :taskings, profile: :account ])
      .where(role: { taskings: { tasks_task_id: task_ids } })
      .to_a

      teacher_students = CourseMembership::Models::TeacherStudent
        .select([
          :id,
          :course_profile_course_id,
          :course_membership_period_id,
          '"tasks_taskings"."tasks_task_id"',
          '"user_profiles"."account_id"'
        ])
        .joins(role: [ :taskings, profile: :account ])
        .where(role: { taskings: { tasks_task_id: task_ids } })
        .to_a

    return if students.empty? && teacher_students.empty?

    account_ids = students.map(&:account_id)

    # Get student names (throws an error if faculty_status is not loaded for some reason)
    student_name_by_account_id = OpenStax::Accounts::Account
      .select([ :id, :username, :first_name, :last_name, :full_name, :faculty_status ])
      .where(id: account_ids)
      .map { |account| [ account.id, account.name ] }
      .to_h
    student_ids_by_task_id = Hash.new { |hash, key| hash[key] = [] }
    teacher_student_ids_by_task_id = Hash.new { |hash, key| hash[key] = [] }
    student_names_by_task_id = Hash.new { |hash, key| hash[key] = [] }
    task_ids_by_course_id = Hash.new { |hash, key| hash[key] = [] }
    period_ids = []
    students.each do |student|
      task_id = student.tasks_task_id
      student_name = student_name_by_account_id[student.account_id]
      student_ids_by_task_id[task_id] << student.id
      student_names_by_task_id[task_id] << student_name
      task_ids_by_course_id[student.course_profile_course_id] << task_id
      period_ids << student.course_membership_period_id
    end
    teacher_students.each do |teacher_student|
      task_id = teacher_student.tasks_task_id
      teacher_student_ids_by_task_id[task_id] << teacher_student.id
      task_ids_by_course_id[teacher_student.course_profile_course_id] << task_id
      period_ids << teacher_student.course_membership_period_id
    end

    # Get all relevant pages
    page_ids = task_steps_by_task_id_and_page_id.values.flat_map(&:keys).compact.uniq
    pages_by_id = Content::Models::Page
      .select([
        :id,
        :uuid,
        :tutor_uuid,
        :title,
        :book_location,
        :baked_book_location,
        :content_chapter_id,
        :content_all_exercises_pool_id
      ])
      .where(id: page_ids)
      .map { |page| Content::Page.new strategy: page.wrap }
      .index_by(&:id)

    # Get all relevant exercise UUIDs
    exercise_ids = exercise_steps.map { |ts| ts.tasked.content_exercise_id }.uniq
    exercise_uuid_by_id = Content::Models::Exercise.where(id: exercise_ids).pluck(:id, :uuid).to_h

    # Get all relevant courses
    course_ids = task_ids_by_course_id.keys
    courses = CourseProfile::Models::Course.select(:id).where(id: course_ids)
                                           .preload(course_ecosystems: :ecosystem)

    # Cache results per task for Quick Look and Student Performance Forecast
    # Pages are mapped to the Course's most recent ecosystem
    task_caches = courses.flat_map do |course|
      task_ids = task_ids_by_course_id[course.id]
      ecosystem_map = run(:get_course_ecosystems_map, course: course).outputs.ecosystems_map
      course_ecosystem = ecosystem_map.to_ecosystem
      page_ids = task_steps_by_task_id_and_page_id.values_at(*task_ids)
                                                  .flat_map(&:keys)
                                                  .compact
                                                  .uniq
      pages = pages_by_id.values_at(*page_ids)
      page_to_page_map = ecosystem_map.map_pages_to_pages pages: pages

      pages_by_mapped_book_chapter_and_page = Hash.new do |hash, key|
        hash[key] = Hash.new { |hash, key| hash[key] = Hash.new { |hash, key| hash[key] = [] } }
      end
      pages_by_book_chapter_and_page = Hash.new do |hash, key|
        hash[key] = Hash.new { |hash, key| hash[key] = Hash.new { |hash, key| hash[key] = [] } }
      end
      mapped_pages = page_to_page_map.values.compact
      pages_to_preload = (pages + mapped_pages).map(&:to_model)
      ActiveRecord::Associations::Preloader.new.preload(
        pages_to_preload, [ :all_exercises_pool, chapter: :book ]
      )
      page_to_page_map.each do |page, mapped_page|
        mapped_page ||= page
        chapter = mapped_page.chapter
        book = chapter.book
        pages_by_mapped_book_chapter_and_page[book][chapter][mapped_page] << page
        pages_by_book_chapter_and_page[book][chapter][page] << page
      end

      task_ids.flat_map do |task_id|
        task = tasks_by_id[task_id]
        task_steps_by_page_id = task_steps_by_task_id_and_page_id[task_id]
        task_steps = task_steps_by_page_id.values.flatten

        num_assigned_steps = task_steps.size
        num_completed_steps = task_steps.count(&:completed?)
        student_ids = student_ids_by_task_id[task_id]
        teacher_student_ids = teacher_student_ids_by_task_id[task_id]
        student_names = student_names_by_task_id[task_id]

        [
          build_task_cache(
            pages_by_mapped_book_chapter_and_page: pages_by_mapped_book_chapter_and_page,
            num_assigned_steps: num_assigned_steps,
            num_completed_steps: num_completed_steps,
            task_steps_by_page_id: task_steps_by_page_id,
            exercise_uuid_by_id: exercise_uuid_by_id,
            ecosystem: course_ecosystem,
            task: task,
            student_ids: student_ids,
            teacher_student_ids: teacher_student_ids,
            student_names: student_names
          )
        ].tap do |task_caches|
          task_caches << build_task_cache(
            pages_by_mapped_book_chapter_and_page: pages_by_book_chapter_and_page,
            num_assigned_steps: num_assigned_steps,
            num_completed_steps: num_completed_steps,
            task_steps_by_page_id: task_steps_by_page_id,
            exercise_uuid_by_id: exercise_uuid_by_id,
            ecosystem: task.ecosystem,
            task: task,
            student_ids: student_ids,
            teacher_student_ids: teacher_student_ids,
            student_names: student_names
          ) if task.ecosystem.id != course_ecosystem.id
        end
      end
    end

    # Update the TaskCaches
    Tasks::Models::TaskCache.import task_caches, validate: false, on_duplicate_key_update: {
      conflict_target: [ :tasks_task_id, :content_ecosystem_id ],
      columns: [
        :opens_at,
        :due_at,
        :feedback_at,
        :student_ids,
        :teacher_student_ids,
        :student_names,
        :as_toc,
        :is_cached_for_period
      ]
    }

    # Update the PeriodCaches
    Tasks::UpdatePeriodCaches.set(queue: queue.to_sym).perform_later(period_ids: period_ids.uniq)
  end

  def build_task_cache(
    pages_by_mapped_book_chapter_and_page:,
    num_assigned_steps:,
    num_completed_steps:,
    task_steps_by_page_id:,
    exercise_uuid_by_id:,
    ecosystem:,
    task:,
    student_ids:,
    teacher_student_ids:,
    student_names:
  )
    books_array = pages_by_mapped_book_chapter_and_page
      .map do |mapped_book, pages_by_mapped_chapter_and_page|
      chapters_array = pages_by_mapped_chapter_and_page
        .map do |mapped_chapter, pages_by_mapped_page|
        pages_array = pages_by_mapped_page.map do |mapped_page, pages|
          page_ids = pages.map(&:id)
          task_steps = task_steps_by_page_id.values_at(*page_ids).flatten
          tasked_exercises = task_steps.select(&:exercise?).map(&:tasked)
          num_tasked_placeholders = task_steps.count(&:placeholder?)

          exercises_array = tasked_exercises.map do |tasked_exercise|
            task_step = tasked_exercise.task_step
            id = tasked_exercise.content_exercise_id
            uuid = exercise_uuid_by_id[id]

            {
              id: id,
              uuid: uuid,
              question_id: tasked_exercise.question_id,
              answer_ids: tasked_exercise.answer_ids,
              step_number: task_step.number,
              group_type: task_step.group_type,
              free_response: tasked_exercise.free_response,
              selected_answer_id: tasked_exercise.answer_id,
              completed: task_step.completed?,
              correct: tasked_exercise.is_correct?
            }
          end
          completed_exercises_array = exercises_array.select { |exercise| exercise[:completed] }

          is_spaced_practice = num_tasked_placeholders == 0 && exercises_array.all? do |ex|
            ex[:group_type] == 'spaced_practice_group'
          end
          {
            id: mapped_page.id,
            tutor_uuid: mapped_page.tutor_uuid,
            title: mapped_page.title,
            book_location: mapped_page.book_location,
            baked_book_location: mapped_page.baked_book_location,
            has_exercises: !mapped_page.all_exercises_pool.empty?,
            is_spaced_practice: is_spaced_practice,
            num_assigned_steps: task_steps.size,
            num_completed_steps: task_steps.count(&:completed?),
            num_assigned_exercises: exercises_array.size,
            num_completed_exercises: completed_exercises_array.size,
            num_correct_exercises: completed_exercises_array.count do |exercise|
              exercise[:correct]
            end,
            num_assigned_placeholders: num_tasked_placeholders,
            exercises: exercises_array
          }
        end.sort_by { |page| page[:book_location] }

        {
          id: mapped_chapter.id,
          tutor_uuid: mapped_chapter.tutor_uuid,
          title: mapped_chapter.title,
          book_location: mapped_chapter.book_location,
          baked_book_location: mapped_chapter.baked_book_location,
          has_exercises: pages_array.any? { |pg| pg[:has_exercises] },
          is_spaced_practice: pages_array.all? { |pg| pg[:is_spaced_practice] },
          num_assigned_steps: pages_array.sum { |pg| pg[:num_assigned_steps] },
          num_completed_steps: pages_array.sum { |pg| pg[:num_completed_steps] },
          num_assigned_exercises: pages_array.sum { |pg| pg[:num_assigned_exercises] },
          num_completed_exercises: pages_array.sum { |pg| pg[:num_completed_exercises] },
          num_correct_exercises: pages_array.sum { |pg| pg[:num_correct_exercises] },
          num_assigned_placeholders: pages_array.sum { |pg| pg[:num_assigned_placeholders] },
          pages: pages_array
        }
      end.sort_by { |chapter| chapter[:book_location] }

      {
        id: mapped_book.id,
        tutor_uuid: mapped_book.tutor_uuid,
        title: mapped_book.title,
        has_exercises: chapters_array.any? { |ch| ch[:has_exercises] },
        num_assigned_steps: chapters_array.sum { |ch| ch[:num_assigned_steps] },
        num_completed_steps: chapters_array.sum { |ch| ch[:num_completed_steps] },
        num_assigned_exercises: chapters_array.sum { |ch| ch[:num_assigned_exercises] },
        num_completed_exercises: chapters_array.sum { |ch| ch[:num_completed_exercises] },
        num_correct_exercises: chapters_array.sum { |ch| ch[:num_correct_exercises] },
        num_assigned_placeholders: chapters_array.sum { |ch| ch[:num_assigned_placeholders] },
        chapters: chapters_array
      }
    end.sort_by { |book| book[:title] }

    toc = {
      id: ecosystem.id,
      tutor_uuid: ecosystem.tutor_uuid,
      title: ecosystem.title,
      has_exercises: books_array.any? { |bk| bk[:has_exercises] },
      num_assigned_steps: num_assigned_steps,
      num_assigned_known_location_steps: books_array.sum { |bk| bk[:num_assigned_steps] },
      num_completed_steps: num_completed_steps,
      num_completed_known_location_steps: books_array.sum { |bk| bk[:num_completed_steps] },
      num_assigned_exercises: books_array.sum { |bk| bk[:num_assigned_exercises] },
      num_completed_exercises: books_array.sum { |bk| bk[:num_completed_exercises] },
      num_correct_exercises: books_array.sum { |bk| bk[:num_correct_exercises] },
      num_assigned_placeholders: books_array.sum { |bk| bk[:num_assigned_placeholders] },
      books: books_array
    }

    Tasks::Models::TaskCache.new(
      task: task,
      ecosystem: ecosystem.to_model,
      task_type: task.task_type,
      opens_at: task.opens_at,
      due_at: task.due_at,
      feedback_at: task.feedback_at,
      student_ids: student_ids,
      teacher_student_ids: teacher_student_ids,
      student_names: student_names,
      as_toc: toc,
      is_cached_for_period: false
    )
  end
end
