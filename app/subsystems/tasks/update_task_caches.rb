# Updates the TaskCaches, used by the Quick Look and Student Performance Forecast
# Tasks not assigned to a student (preview tasks) are ignored
class Tasks::UpdateTaskCaches
  lev_routine active_job_enqueue_options: { queue: :dashboard }, transaction: :read_committed

  uses_routine GetCourseEcosystemsMap, as: :get_course_ecosystems_map

  protected

  def exec(task_ids:, update_cached_attributes: false, background: true, queue: 'dashboard')
    ScoutHelper.ignore!(0.995)

    task_ids = [task_ids].flatten

    # Attempt to lock the tasks; Skip tasks already locked by someone else
    tasks = Tasks::Models::Task
      .where(id: task_ids)
      .lock('FOR NO KEY UPDATE SKIP LOCKED')
      .preload(:task_plan, :ecosystem, :time_zone, taskings: { role: { student: :period } })
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
      .select(
        :tasks_task_id,
        :number,
        :first_completed_at,
        :last_completed_at,
        :content_page_id,
        :group_type,
        :is_core,
        :tasked_type,
        :tasked_id
      )
      .where(tasks_task_id: task_ids)
      .order(:number)
      .to_a

    # Preload all TaskedExercises
    exercise_steps = task_steps.select(&:exercise?)
    ActiveRecord::Associations::Preloader.new.preload exercise_steps, :tasked

    exercise_ids = exercise_steps.map(&:tasked).map(&:content_exercise_id)
    exercise_uuid_by_id = Content::Models::Exercise.where(id: exercise_ids).pluck(:id, :uuid).to_h

    # Preload all TaskedPlaceholders
    placeholder_steps = task_steps.select(&:placeholder?)
    ActiveRecord::Associations::Preloader.new.preload placeholder_steps, :tasked

    # Group TaskSteps by task_id
    task_steps_by_task_id = task_steps.group_by(&:tasks_task_id)

    # Update step counts for each task
    if update_cached_attributes
      tasks = tasks.map do |task|
        task_steps = task_steps_by_task_id.fetch(task.id, [])
        task.update_cached_attributes steps: task_steps
      end

      # Update the Task cache columns (scores cache)
      Tasks::Models::Task.import tasks, validate: false, on_duplicate_key_update: {
        conflict_target: [ :id ], columns: Tasks::Models::Task::CACHE_COLUMNS
      }
    end

    # Get all page_ids
    page_ids = task_steps.map(&:content_page_id).uniq

    # Get Page uuids
    unmapped_page_tutor_uuid_by_id = Content::Models::Page.where(id: page_ids).pluck(
      :id, :tutor_uuid
    ).to_h

    # Get student and course IDs
    students = CourseMembership::Models::Student
      .select(
        :id,
        :course_profile_course_id,
        :course_membership_period_id,
        '"tasks_taskings"."tasks_task_id"',
        '"user_profiles"."account_id"'
      )
      .joins(role: [ :taskings, profile: :account ])
      .where(role: { taskings: { tasks_task_id: task_ids } })
      .to_a

    teacher_students = CourseMembership::Models::TeacherStudent
      .select(
        :id,
        :course_profile_course_id,
        :course_membership_period_id,
        '"tasks_taskings"."tasks_task_id"',
        '"user_profiles"."account_id"'
      )
      .joins(role: [ :taskings, profile: :account ])
      .where(role: { taskings: { tasks_task_id: task_ids } })
      .to_a

    account_ids = students.map(&:account_id)

    # Get student names (throws an error if faculty_status is not loaded for some reason)
    student_name_by_account_id = OpenStax::Accounts::Account
      .select(:id, :username, :first_name, :last_name, :full_name, :faculty_status)
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

    # Get all relevant courses
    course_ids = task_ids_by_course_id.keys
    courses = CourseProfile::Models::Course.select(:id)
                                           .where(id: course_ids)
                                           .preload(course_ecosystems: :ecosystem)

    # Cache results per task for Quick Look and Student Performance Forecast
    # Pages are mapped to the Course's most recent ecosystem
    task_caches = courses.flat_map do |course|
      task_ids = task_ids_by_course_id[course.id]
      ecosystem_map = run(:get_course_ecosystems_map, course: course).outputs.ecosystems_map
      course_ecosystem = ecosystem_map.to_ecosystem
      page_ids = task_steps_by_task_id.values_at(
        *task_ids
      ).compact.flatten.map(&:content_page_id).uniq
      page_id_to_page_id_map = ecosystem_map.map_page_ids page_ids: page_ids

      task_ids.flat_map do |task_id|
        task = tasks_by_id[task_id]
        task_steps = task_steps_by_task_id.fetch(task_id, [])

        task_steps_by_page_id = Hash.new { |hash, key| hash[key] = [] }
        task_steps.each do |task_step|
          page_id = task_step.content_page_id
          task_steps_by_page_id[page_id] << task_step

          mapped_page_id = page_id_to_page_id_map[page_id]
          next if mapped_page_id.nil? || mapped_page_id == page_id

          task_steps_by_page_id[mapped_page_id] << task_step
        end

        num_assigned_steps = task_steps.size
        num_completed_steps = task_steps.count(&:completed?)
        student_ids = student_ids_by_task_id[task_id]
        teacher_student_ids = teacher_student_ids_by_task_id[task_id]
        student_names = student_names_by_task_id[task_id]

        [
          build_task_cache(
            num_assigned_steps: num_assigned_steps,
            num_completed_steps: num_completed_steps,
            task_steps_by_page_id: task_steps_by_page_id,
            exercise_uuid_by_id: exercise_uuid_by_id,
            unmapped_page_tutor_uuid_by_id: unmapped_page_tutor_uuid_by_id,
            ecosystem: course_ecosystem,
            task: task,
            student_ids: student_ids,
            teacher_student_ids: teacher_student_ids,
            student_names: student_names
          )
        ].tap do |task_caches|
          task_caches << build_task_cache(
            num_assigned_steps: num_assigned_steps,
            num_completed_steps: num_completed_steps,
            task_steps_by_page_id: task_steps_by_page_id,
            exercise_uuid_by_id: exercise_uuid_by_id,
            unmapped_page_tutor_uuid_by_id: unmapped_page_tutor_uuid_by_id,
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
        :tasks_task_plan_id,
        :opens_at,
        :due_at,
        :feedback_at,
        :withdrawn_at,
        :student_ids,
        :teacher_student_ids,
        :student_names,
        :as_toc,
        :is_cached_for_period
      ]
    }

    # Update the PeriodCaches
    period_ids = period_ids.uniq
    if background
      Tasks::UpdatePeriodCaches.set(queue: queue.to_sym).perform_later(period_ids: period_ids)
    else
      Tasks::UpdatePeriodCaches.call(period_ids: period_ids)
    end
  end

  def build_task_cache(
    num_assigned_steps:,
    num_completed_steps:,
    task_steps_by_page_id:,
    exercise_uuid_by_id:,
    unmapped_page_tutor_uuid_by_id:,
    ecosystem:,
    task:,
    student_ids:,
    teacher_student_ids:,
    student_names:
  )
    task_plan = task.task_plan

    books_array = ecosystem.books.map do |book|
      chapters_array = book.chapters.map do |chapter|
        pages_array = chapter.pages.map do |page|
          task_steps = task_steps_by_page_id[page.id]
          next if task_steps.empty?

          unmapped_page_ids = task_steps.map(&:content_page_id).uniq
          unmapped_page_tutor_uuids = unmapped_page_tutor_uuid_by_id.values_at(*unmapped_page_ids)
          unmapped_page_tutor_uuids = (
            unmapped_page_tutor_uuids + [ page.tutor_uuid ]
          ).uniq if unmapped_page_ids.include? page.id
          tasked_exercises = task_steps.select(&:exercise?).map(&:tasked)
          num_tasked_placeholders = task_steps.count(&:placeholder?)

          exercises_array = tasked_exercises.map do |tasked_exercise|
            task_step = tasked_exercise.task_step
            id = tasked_exercise.content_exercise_id

            {
              id: id,
              uuid: exercise_uuid_by_id[id],
              question_id: tasked_exercise.question_id,
              answer_ids: tasked_exercise.answer_ids,
              step_number: task_step.number,
              group_type: task_step.group_type,
              free_response: tasked_exercise.free_response,
              selected_answer_id: tasked_exercise.answer_id,
              completed: task_step.completed?,
              correct: tasked_exercise.is_correct?,
              first_completed_at: task_step.first_completed_at,
              last_completed_at: task_step.last_completed_at
            }
          end
          completed_ex_array = exercises_array.select { |exercise| exercise[:completed] }

          is_spaced_practice = num_tasked_placeholders == 0 && exercises_array.all? do |ex|
            ex[:group_type] == 'spaced_practice_group'
          end
          {
            id: page.id,
            unmapped_ids: unmapped_page_ids,
            tutor_uuid: page.tutor_uuid,
            unmapped_tutor_uuids: unmapped_page_tutor_uuids,
            title: page.title,
            book_location: page.book_location,
            has_exercises: !page.all_exercise_ids.empty?,
            is_spaced_practice: is_spaced_practice,
            num_assigned_steps: task_steps.size,
            num_completed_steps: task_steps.count(&:completed?),
            num_assigned_exercises: exercises_array.size,
            num_completed_exercises: completed_ex_array.size,
            num_correct_exercises: completed_ex_array.count { |ex| ex[:correct] },
            num_assigned_placeholders: num_tasked_placeholders,
            first_worked_at: completed_ex_array.map { |ex| ex[:first_completed_at] }.compact.min,
            last_worked_at: completed_ex_array.map { |ex| ex[:last_completed_at] }.compact.max,
            exercises: exercises_array
          }
        end.compact.sort_by { |page| page[:book_location] }
        next if pages_array.empty?

        {
          tutor_uuid: chapter.tutor_uuid,
          title: chapter.title,
          book_location: chapter.book_location,
          has_exercises: pages_array.any? { |pg| pg[:has_exercises] },
          is_spaced_practice: pages_array.all? { |pg| pg[:is_spaced_practice] },
          num_assigned_steps: pages_array.sum { |pg| pg[:num_assigned_steps] },
          num_completed_steps: pages_array.sum { |pg| pg[:num_completed_steps] },
          num_assigned_exercises: pages_array.sum { |pg| pg[:num_assigned_exercises] },
          num_completed_exercises: pages_array.sum { |pg| pg[:num_completed_exercises] },
          num_correct_exercises: pages_array.sum { |pg| pg[:num_correct_exercises] },
          num_assigned_placeholders: pages_array.sum { |pg| pg[:num_assigned_placeholders] },
          first_worked_at: pages_array.map { |pg| pg[:first_worked_at] }.compact.min,
          last_worked_at: pages_array.map { |pg| pg[:last_worked_at] }.compact.max,
          pages: pages_array
        }
      end.compact.sort_by { |chapter| chapter[:book_location] }
      next if chapters_array.empty?

      {
        id: book.id,
        tutor_uuid: book.tutor_uuid,
        title: book.title,
        has_exercises: chapters_array.any? { |ch| ch[:has_exercises] },
        num_assigned_steps: chapters_array.sum { |ch| ch[:num_assigned_steps] },
        num_completed_steps: chapters_array.sum { |ch| ch[:num_completed_steps] },
        num_assigned_exercises: chapters_array.sum { |ch| ch[:num_assigned_exercises] },
        num_completed_exercises: chapters_array.sum { |ch| ch[:num_completed_exercises] },
        num_correct_exercises: chapters_array.sum { |ch| ch[:num_correct_exercises] },
        num_assigned_placeholders: chapters_array.sum { |ch| ch[:num_assigned_placeholders] },
        first_worked_at: chapters_array.map { |ch| ch[:first_worked_at] }.compact.min,
        last_worked_at: chapters_array.map { |ch| ch[:last_worked_at] }.compact.max,
        chapters: chapters_array
      }
    end.compact.sort_by { |book| book[:title] }

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
      task_plan: task_plan,
      ecosystem: ecosystem,
      task_type: task.task_type,
      opens_at: task.opens_at,
      due_at: task.due_at,
      feedback_at: task.feedback_at,
      student_ids: student_ids,
      teacher_student_ids: teacher_student_ids,
      student_names: student_names,
      withdrawn_at: task_plan&.withdrawn_at,
      as_toc: toc,
      is_cached_for_period: false
    )
  end
end
