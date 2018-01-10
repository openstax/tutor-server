class ExportAndUploadResearchData

  BATCH_SIZE = 1000

  lev_routine active_job_enqueue_options: { queue: :lowest_priority }, express_output: :filename

  def exec(filename: nil, task_types: [], from: nil, to: nil)
    fatal_error(code: :tasks_types_missing, message: "You must specify the types of Tasks") \
      if task_types.blank?

    filename = FilenameSanitizer.sanitize(filename) ||
               "export_#{Time.current.strftime("%Y%m%dT%H%M%SZ")}.csv"
    date_range = (Chronic.parse(from))..(Chronic.parse(to)) unless to.blank? || from.blank?

    tutor_export_file = create_tutor_export_file("tutor_#{filename}", task_types, date_range)
    cnx_export_file = create_cnx_export_file("cnx_#{filename}", task_types, date_range)
    exercises_export_file = create_exercises_export_file(
      "exercises_#{filename}", task_types, date_range
    )
    files = [ tutor_export_file, cnx_export_file, exercises_export_file ]

    zip_filename = "#{filename.gsub(File.extname(filename), '')}.zip"
    Box.upload_files zip_filename: zip_filename, files: files

    files.each { |file| File.delete(file) if File.exist?(file) }

    outputs.filename = filename
  end

  protected

  def format_time(time)
    return time if time.blank?

    time.utc.iso8601
  end

  def create_tutor_export_file(filename, task_types, date_range)
    File.join('tmp', 'exports', filename).tap do |filepath|
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
          "CNX JSON URL",
          "CNX HTML URL",
          "HTML Fragment Number",
          "Exercise JSON URL",
          "Exercise Editor URL",
          "Exercise Tags",
          "Question ID",
          "Question Correct Answer ID",
          "Question Free Response",
          "Question Chosen Answer ID",
          "Question Correct?"
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
          .order(:id)
        steps = steps.where(task: { created_at: date_range }) if date_range

        ordered_find_in_batches(steps) do |steps|
          task_ids = steps.map(&:tasks_task_id)
          tasks = Tasks::Models::Task.where(id: task_ids).preload(:taskings, :time_zone)
          tasks_by_task_id = tasks.index_by(&:id)

          role_ids = tasks.map { |task| task.taskings.first.entity_role_id }.uniq

          research_identifier_by_role_id = {}
          course_id_by_role_id = {}
          is_cc_by_role_id = {}
          CourseMembership::Models::Student
            .joins(:course, :role)
            .where(entity_role_id: role_ids, course: { is_preview: false, is_test: false })
            .pluck(
              :entity_role_id, :research_identifier, :course_profile_course_id, :is_concept_coach
            )
            .each do |role_id, research_identifier, course_id, is_cc|
              research_identifier_by_role_id[role_id] = research_identifier
              course_id_by_role_id[role_id] = course_id
              is_cc_by_role_id[role_id] = is_cc.to_s.upcase
          end

          exercise_steps = steps.select(&:exercise?)
          tasked_exercise_ids = exercise_steps.map(&:tasked_id)
          tasked_exercises_by_id = Tasks::Models::TaskedExercise.select(
            [
              :id,
              :url,
              :question_id,
              :correct_answer_id,
              :answer_id,
              :free_response,
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

              research_identifier = research_identifier_by_role_id[role_id]
              course_id = course_id_by_role_id[role_id]
              is_cc = is_cc_by_role_id[role_id]
              next if research_identifier.nil? || course_id.nil? || is_cc.nil?

              type = step.tasked_type.match(/Tasked(.+)\z/).try!(:[], 1)
              page_url = step.page.try!(:url)
              page_json_url = "#{page_url}.json" unless page_url.nil?

              row = [
                research_identifier,
                course_id,
                is_cc,
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
                page_json_url,
                page_url,
                step.fragment_index.try!(:+, 1)
              ]

              row.concat(
                step.exercise? ? [
                  "#{tasked_exercise.url.gsub('org', 'org/api')}.json",
                  tasked_exercise.url,
                  tasked_exercise.tags_array.join(','),
                  tasked_exercise.question_id,
                  tasked_exercise.correct_answer_id,
                  # escape so Excel doesn't see as formula
                  tasked_exercise.free_response.try!(:sub, /\A=/, "'="),
                  tasked_exercise.answer_id,
                  tasked_exercise.is_correct?
                ] : [ nil ] * 7
              )

              file << row
            rescue StandardError => ex
              raise ex if !Rails.env.production? || ex.is_a?(Timeout::Error)

              Rails.logger.error do
                "Skipped step #{step.id} due to #{ex.inspect} @ #{ex.backtrace.first}"
              end
            end
          end
        end
      end
    end
  end

  def create_cnx_export_file(filename, task_types, date_range)
    File.join('tmp', 'exports', filename).tap do |filepath|
      CSV.open(filepath, 'w') do |file|
        file << [
          "CNX JSON URL",
          "CNX HTML URL",
          "CNX Book Name",
          "CNX Chapter Number",
          "CNX Chapter Name",
          "CNX Section Number",
          "CNX Section Name",
          "HTML Fragment Number",
          "HTML Fragment Labels",
          "HTML Fragment Content"
        ]

        pages = Content::Models::Page
          .select(
            [
              'DISTINCT ON ("content_pages"."url", "content_books"."title") "content_pages"."url"',
              '"content_books"."title" AS "book_title"',
              '"content_chapters"."number" AS "chapter_number"',
              '"content_chapters"."title" AS "chapter_title"',
              :number,
              :title,
              :fragments
            ]
          )
          .joins(task_steps: { task: :taskings }, chapter: :book)
          .where(task_steps: { task: { task_type: task_types } })
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
        pages = pages.where(task_steps: { task: { created_at: date_range } }) if date_range

        ordered_find_in_batches(pages, [ :url, '"content_books"."title"' ]) do |pgs|
          pgs.each do |page|
            page.fragments.each_with_index do |fragment, fragment_index|
              begin
                row = [
                  "#{page.url}.json",
                  page.url,
                  page.book_title,
                  page.chapter_number,
                  page.chapter_title,
                  page.number,
                  page.title,
                  fragment_index + 1,
                  fragment.labels.join(','),
                  fragment.try(:to_html)
                ]

                file << row
              rescue StandardError => ex
                raise ex if !Rails.env.production? || ex.is_a?(Timeout::Error)

                Rails.logger.error do
                  "Skipped page #{page.id} fragment #{fragment_index + 1
                  } due to #{ex.inspect} @ #{ex.backtrace.first}"
                end
              end
            end
          end
        end
      end
    end
  end

  def create_exercises_export_file(filename, task_types, date_range)
    File.join('tmp', 'exports', filename).tap do |filepath|
      CSV.open(filepath, 'w') do |file|
        file << [
          "Exercise JSON URL",
          "Exercise Editor URL",
          "Exercise Tags",
          "Question ID",
          "Question Content"
        ]

        exercises = Content::Models::Exercise
          .select(
            [
              'DISTINCT ON ("content_exercises"."url") "content_exercises"."url"',
              :content,
              <<-TAGS_SQL.strip_heredoc
                (
                  SELECT COALESCE(ARRAY_AGG("content_tags"."value"), ARRAY[]::varchar[])
                  FROM "content_exercise_tags"
                  INNER JOIN "content_tags"
                    ON "content_tags"."id" = "content_exercise_tags"."content_tag_id"
                  WHERE "content_exercise_tags"."content_exercise_id" = "content_exercises"."id"
                ) AS "tags_array"
              TAGS_SQL
            ]
          )
          .joins(tasked_exercises: { task_step: { task: :taskings } })
          .where(tasked_exercises: { task_step: { task: { task_type: task_types } } })
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
        exercises = exercises.where(
          tasked_exercises: { task_step: { task: { created_at: date_range } } }
        ) if date_range

        ordered_find_in_batches(exercises, :url) do |exs|
          exs.each do |exercise|
            url = exercise.url
            api_url = "#{exercise.url.gsub('org', 'org/api')}.json"
            tags = exercise.tags_array.join(',')

            exercise.content_as_independent_questions.each do |question|
              begin
                row = [
                  api_url,
                  url,
                  tags,
                  question[:id],
                  question[:content]
                ]

                file << row
              rescue StandardError => ex
                raise ex if !Rails.env.production? || ex.is_a?(Timeout::Error)

                Rails.logger.error do
                  "Skipped exercise #{exercise.id} question #{question.try(:[], :id)
                  } due to #{ex.inspect} @ #{ex.backtrace.first}"
                end
              end
            end
          end
        end
      end
    end
  end

  def ordered_find_in_batches(relation, order_bys = :id, batch_size = BATCH_SIZE)
    relation = relation.dup.reorder(order_bys).limit(batch_size)
    order_bys = [ order_bys ].flatten
    arel_table = relation.arel_table

    wheres = nil
    loop do
      records = relation.where(wheres || {}).to_a

      yield records

      break if records.size < batch_size

      last_record = records.last
      previous_eqs_array = []
      wheres = order_bys.map do |column, direction|
        value = last_record.public_send(column)
        operator = direction.to_s.upcase == 'DESC' ? :lt : :gt

        previous_eqs = previous_eqs_array.reduce(:and)
        clause = arel_table[column].public_send(operator, value)
        clause = clause.and(previous_eqs) unless previous_eqs.empty?
        previous_eqs_array << arel_table[column].eq(value)
        clause
      end.reduce(:or)
    end
  end

end
