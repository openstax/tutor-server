class ExportAndUploadResearchData

  lev_routine active_job_enqueue_options: { queue: :lowest_priority }, express_output: :filename

  def exec(filename: nil, task_types: [], from: nil, to: nil)
    fatal_error(code: :tasks_types_missing, message: "You must specify the types of Tasks") \
      if task_types.blank?
    outputs[:filename] = FilenameSanitizer.sanitize(filename) ||
                         "export_#{Time.now.utc.strftime("%Y%m%dT%H%M%SZ")}.csv"
    date_range = (Chronic.parse(from))..(Chronic.parse(to)) unless to.blank? || from.blank?
    create_export_file(task_types, date_range)
    upload_export_file
    remove_export_file
  end

  protected

  def filepath
    File.join 'tmp', 'exports', outputs[:filename]
  end

  def create_export_file(task_types, date_range)
    CSV.open(filepath, 'w') do |file|
      file << [
        "Student Research Identifier",
        "Course ID",
        "Concept Coach?",
        "Period ID",
        "Plan ID",
        "Task ID",
        "Task Type",
        "Task Opens At",
        "Task Due At",
        "Step ID",
        "Step Number",
        "Step Type",
        "Step Group",
        "Step Labels",
        "Step First Completed At",
        "Step Last Completed At",
        "CNX Module JSON URL",
        "CNX Module HTML URL",
        "HTML Fragment Number",
        "Exercise JSON URL",
        "Exercise Editor URL",
        "Exercise Correct Answer ID",
        "Exercise Chosen Answer ID",
        "Exercise Correct?",
        "Exercise Free Response",
        "Exercise Tags"
      ]

      steps = Tasks::Models::TaskStep
        .joins(task: :taskings)
        .where(task: { task_type: task_types })
        .where(
          <<-SQL.strip_heredoc
            NOT EXISTS (
              SELECT *
              FROM "tasks_task_plans"
              WHERE "tasks_task_plans"."id" = "tasks_tasks"."tasks_task_plan_id"
                AND "tasks_task_plans"."is_preview" = TRUE
            )
          SQL
        )
      steps = steps.where(task: { created_at: date_range }) if date_range

      # find_in_batches completely ignores any sort of limit or order
      steps.find_in_batches do |steps|
        task_ids = steps.map(&:tasks_task_id)
        tasks_by_task_id = Tasks::Models::Task.where(id: task_ids)
                                              .preload(:taskings, :time_zone)
                                              .index_by(&:id)

        exercise_steps = steps.select(&:exercise?)
        tasked_exercise_ids = exercise_steps.map(&:tasked_id)
        tasked_exercises_by_id = Tasks::Models::TaskedExercise.select(
          [
            :id,
            :url,
            :free_response,
            :answer_id,
            :correct_answer_id,
            'COALESCE("answer_id" = "correct_answer_id", FALSE) AS "is_correct"',
            <<-TAGS_SQL.strip_heredoc
              (
                SELECT COALESCE(ARRAY_AGG("content_tags"."value"), ARRAY[]::varchar[])
                FROM "content_exercises"
                INNER JOIN "content_exercise_tags"
                  ON "content_exercise_tags"."content_exercise_id" = "content_exercises"."id"
                INNER JOIN "content_tags"
                  ON "content_tags"."id" = "content_exercise_tags"."content_tag_id"
                INNER JOIN "content_pages"
                  ON "content_pages"."id" = "content_exercises"."content_page_id"
                WHERE "content_exercises"."id" = "tasks_tasked_exercises"."content_exercise_id"
                AND (
                  "content_tags"."tag_type" != #{Content::Models::Tag.tag_types[:cnxmod]}
                  OR "content_tags"."value" = 'context-cnxmod:' || "content_pages"."uuid"
                )
              ) AS "tags_array"
            TAGS_SQL
          ]
        ).where(id: tasked_exercise_ids).index_by(&:id)

        steps.each do |step|
          begin
            task = tasks_by_task_id[step.tasks_task_id]
            next if task.nil?

            tasked_exercise = tasked_exercises_by_id[step.tasked_id]
            next if step.exercise? && tasked_exercise.nil?

            role_id = task.taskings.first.entity_role_id
            r_info = role_info[role_id]
            next if r_info.nil?

            type = step.tasked_type.match(/Tasked(.+)\z/).try!(:[], 1)
            course_id = r_info[:course_id]
            page = step.page

            row = [
              r_info[:research_identifier],
              course_id,
              is_cc?(course_id),
              task.taskings.first.course_membership_period_id,
              task.tasks_task_plan_id,
              task.id,
              task.task_type,
              format_time(task.opens_at),
              format_time(task.due_at),
              step.id,
              step.number,
              type,
              step.group_name,
              step.labels.join(','),
              format_time(step.first_completed_at),
              format_time(step.last_completed_at),
              "#{page.url}.json",
              page.url,
              step.fragment_index.try!(:+, 1)
            ]

            row.concat(
              step.exercise? ? [
                tasked_exercise.url.gsub("org", "org/api") + ".json",
                tasked_exercise.url,
                tasked_exercise.correct_answer_id,
                tasked_exercise.answer_id,
                tasked_exercise.is_correct,
                # escape so Excel doesn't see as formula
                tasked_exercise.free_response.try!(:sub, /\A=/, "'="),
                tasked_exercise.tags_array.join(',')
              ] : [ nil ] * 7
            )

            file << row
          rescue StandardError => ex
            raise ex if ex.is_a? Timeout::Error

            Rails.logger.error do
              "Skipped step #{step.id} for #{ex.inspect} @ #{ex.try(:backtrace).try(:first)}\n"
            end
          end
        end
      end
    end
  end

  # TODO: Fix (will OOM with too many students in the system)
  def role_info
    @role_info ||= {}.tap do |role_info|
      CourseMembership::Models::Student
        .joins(:course, :role)
        .where(course: { is_preview: false, is_test: false })
        .pluck(:entity_role_id, :course_profile_course_id, :research_identifier)
        .each do |entity_role_id, course_profile_course_id, research_identifier|
          role_info[entity_role_id] = {
            research_identifier: research_identifier,
            course_id: course_profile_course_id
          }
        end
    end
  end

  def is_cc?(course_id)
    @is_cc_map ||= CourseProfile::Models::Course.pluck(:id, :is_concept_coach).to_h

    @is_cc_map[course_id].to_s.upcase
  end

  def format_time(time)
    return time if time.blank?
    time.utc.iso8601
  end

  def upload_export_file
    Box.upload_file filepath
  end

  def remove_export_file
    File.delete(filepath) if File.exist?(filepath)
  end

end
