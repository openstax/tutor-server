# Updates the TaskPageCaches, used in the Performance Forecast and Quick Look
# Tasks not assigned to a student (preview tasks) are ignored
class Tasks::UpdateTaskPageCaches
  lev_routine

  uses_routine GetCourseEcosystemsMap, as: :get_course_ecosystems_map

  protected

  def exec(tasks:)
    task_ids = [tasks].flatten.map(&:id)

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

    # Get exercise counts for each page of each task
    exercise_counts_by_task_id = Tasks::Models::TaskedExercise
      .select([
        '"tasks_task_steps"."tasks_task_id"',
        '"tasks_task_steps"."content_page_id"',
        'COUNT(*) AS "assigned"',
        'COUNT("tasks_task_steps"."first_completed_at") AS "completed"',
        'COUNT(*) FILTER (WHERE "tasks_tasked_exercises"."answer_id" =' +
          '"tasks_tasked_exercises"."correct_answer_id") AS "correct"'
      ])
      .joins(:task_step)
      .where(task_step: { tasks_task_id: task_ids })
      .group(task_step: [ :tasks_task_id, :content_page_id ])
      .group_by(&:tasks_task_id)

    # Get all relevant pages
    page_ids = exercise_counts_by_task_id.values.flatten.map(&:content_page_id)
    pages_by_page_id = Content::Models::Page.select(:id).where(id: page_ids).map do |page|
      Content::Page.new strategy: page.wrap
    end.index_by(&:id)

    # Get all relevant courses
    course_ids = task_ids_by_course_id.keys
    courses = CourseProfile::Models::Course.select(:id).where(id: course_ids).preload(:ecosystems)

    # Cache results per student per task per CNX section for Quick Look and Performance Forecast
    # Pages are mapped to the Course's most recent ecosystem
    task_page_caches = courses.flat_map do |course|
      task_ids = task_ids_by_course_id[course.id]
      ecosystem_map = run(:get_course_ecosystems_map, course: course).outputs.ecosystems_map

      task_ids.flat_map do |task_id|
        exercise_counts = exercise_counts_by_task_id[task_id] || []
        page_ids = exercise_counts.map(&:content_page_id)
        pages = pages_by_page_id.values_at(*page_ids)

        page_to_page_map = ecosystem_map.map_pages_to_pages pages: pages

        student_ids = student_ids_by_task_id[task_id]

        exercise_counts.flat_map do |exercise_count|
          page_id = exercise_count.content_page_id
          page = pages_by_page_id[page_id]
          mapped_page_id = page_to_page_map[page].try!(:id)

          student_ids.map do |student_id|
            Tasks::Models::TaskPageCache.new(
              tasks_task_id: task_id,
              course_membership_student_id: student_id,
              content_page_id: page_id,
              content_mapped_page_id: mapped_page_id,
              num_assigned_exercises: exercise_count.assigned,
              num_completed_exercises: exercise_count.completed,
              num_correct_exercises: exercise_count.correct
            )
          end
        end
      end
    end

    Tasks::Models::TaskPageCache.import task_page_caches, validate: false,
                                                          on_duplicate_key_update: {
      conflict_target: [ :course_membership_student_id, :content_page_id, :tasks_task_id ],
      columns: [
        :content_mapped_page_id,
        :num_assigned_exercises,
        :num_completed_exercises,
        :num_correct_exercises
      ]
    }
  end
end
