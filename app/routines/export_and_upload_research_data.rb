class ExportAndUploadResearchData

  lev_routine active_job_enqueue_options: { queue: :long_running }, express_output: :filename

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
        "Student",
        "Course ID",
        "CC?",
        "Period ID",
        "Plan ID",
        "Task ID",
        "Task Type",
        "Step ID",
        "Step Number",
        "Step Type",
        "Group",
        "First Completed At",
        "Last Completed At",
        "Opens At",
        "Due At",
        "URL",
        "API URL",
        "Correct Answer ID",
        "Answer ID",
        "Correct?",
        "Free Response",
        "Tags"
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

        taskeds_by_tasked_type_and_tasked_id = Hash.new { |hash, key| hash[key] = {} }
        steps.group_by(&:tasked_type).each do |tasked_type, steps|
          tasked_class = tasked_type.constantize
          tasked_ids = steps.map(&:tasked_id)
          taskeds = tasked_class.where(id: tasked_ids).select(
            case tasked_type
            when Tasks::Models::TaskedExercise.name
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
                    WHERE "content_exercises"."id" = "tasks_tasked_exercises"."content_exercise_id"
                  ) AS "tags_array"
                TAGS_SQL
              ]
            when Tasks::Models::TaskedPlaceholder.name
              [ :id ]
            else
              [ :id, :url ]
            end
          )

          taskeds.each do |tasked|
            taskeds_by_tasked_type_and_tasked_id[tasked_type][tasked.id] = tasked
          end
        end

        steps.each do |step|
          begin
            task = tasks_by_task_id[step.tasks_task_id]
            next if task.nil?

            tasked = taskeds_by_tasked_type_and_tasked_id[step.tasked_type][step.tasked_id]
            next if tasked.nil?

            role_id = task.taskings.first.entity_role_id
            r_info = role_info[role_id]
            next if r_info.nil?

            type = step.tasked_type.match(/Tasked(.+)\z/).try!(:[], 1)
            course_id = r_info[:course_id]
            url = tasked.url if tasked.respond_to?(:url)

            row = [
              r_info[:research_identifier],
              course_id,
              is_cc?(course_id),
              task.taskings.first.course_membership_period_id,
              task.tasks_task_plan_id,
              task.id,
              task.task_type,
              step.id,
              step.number,
              type,
              step.group_name,
              format_time(step.first_completed_at),
              format_time(step.last_completed_at),
              format_time(task.opens_at),
              format_time(task.due_at),
              url
            ]

            row.push(*(
              case type
              when 'Exercise'
                [
                  url.gsub("org", "org/api") + ".json",
                  tasked.correct_answer_id,
                  tasked.answer_id,
                  tasked.is_correct,
                  # escape so Excel doesn't see as formula
                  tasked.free_response.try!(:gsub, /\A=/, "'="),
                  tasked.tags_array.join(',')
                ]
              when 'Reading'
                [ "#{url}.json" ] + [ nil ] * 4
              else
                [ nil ] * 5
              end
            ))

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
