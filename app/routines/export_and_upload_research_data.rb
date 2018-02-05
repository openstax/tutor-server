class ExportAndUploadResearchData

  BATCH_SIZE = 1000

  lev_routine active_job_enqueue_options: { queue: :lowest_priority },
              express_output: :filename,
              transaction: :no_transaction

  def exec(filename: nil, task_types: [], from: nil, to: nil)
    fatal_error(code: :tasks_types_missing, message: "You must specify the types of Tasks") \
      if task_types.blank?

    filename = FilenameSanitizer.sanitize(filename) ||
               "export_#{Time.current.strftime("%Y%m%dT%H%M%SZ")}.csv"
    date_range = (Chronic.parse(from))..(Chronic.parse(to)) unless to.blank? || from.blank?

    nested_transaction = ActiveRecord::Base.connection.transaction_open?
    files = ActiveRecord::Base.transaction do
      ActiveRecord::Base.connection.execute(
        'SET TRANSACTION ISOLATION LEVEL SERIALIZABLE READ ONLY DEFERRABLE'
      ) unless nested_transaction

      tutor_export_file, page_ids, exercise_ids = create_tutor_export_file(
        "tutor_#{filename}", task_types, date_range
      )

      [
        tutor_export_file,
        create_cnx_export_file("cnx_#{filename}", page_ids),
        create_exercises_export_file("exercises_#{filename}", exercise_ids)
      ]
    end

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
    page_ids = []
    exercise_ids = []

    export_file = File.join('tmp', 'exports', filename).tap do |filepath|
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

        te = Tasks::Models::TaskedExercise.arel_table
        pg = Content::Models::Page.arel_table
        er = Entity::Role.arel_table
        co = CourseProfile::Models::Course.arel_table
        steps = Tasks::Models::TaskStep
          .select([
            Tasks::Models::TaskStep.arel_table[ Arel.star ],
            te[:content_exercise_id].as('exercise_id'),
            te[:url].as('exercise_url'),
            te[:question_id],
            te[:correct_answer_id],
            te[:answer_id],
            te[:free_response],
            pg[:id].as('page_id'),
            pg[:url].as('page_url'),
            er[:research_identifier],
            co[:id].as('course_id'),
            co[:is_concept_coach],
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
          ])
          .joins(task: { taskings: { role: { student: :course } } })
          .joins(
            <<-JOIN_SQL.strip_heredoc
              LEFT OUTER JOIN "tasks_tasked_exercises"
                ON "tasks_task_steps"."tasked_type" = 'Tasks::Models::TaskedExercise'
                AND "tasks_task_steps"."tasked_id" = "tasks_tasked_exercises"."id"
            JOIN_SQL
          )
          .joins(
            <<-JOIN_SQL.strip_heredoc
              LEFT OUTER JOIN "content_pages"
                ON "content_pages"."id" = "tasks_task_steps"."content_page_id"
            JOIN_SQL
          )
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
          .preload(task: :time_zone)
        steps = steps.where(task: { created_at: date_range }) if date_range

        ordered_find_in_batches(steps) do |sts|
          page_ids.concat sts.map(&:page_id)
          exercise_ids.concat sts.map(&:exercise_id)

          sts.each do |step|
            begin
              task = step.task
              type = step.tasked_type.match(/Tasked(.+)\z/).try!(:[], 1)

              page_url = step.page_url
              page_json_url = "#{page_url}.json" unless page_url.nil?

              row = [
                step.research_identifier,
                step.course_id,
                step.is_concept_coach.to_s.upcase,
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
                  "#{step.exercise_url.gsub('org', 'org/api')}.json",
                  step.exercise_url,
                  step.tags_array.join(','),
                  step.question_id,
                  step.correct_answer_id,
                  # escape so Excel doesn't see as formula
                  step.free_response.try!(:sub, /\A=/, "'="),
                  step.answer_id,
                  step.answer_id == step.correct_answer_id
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

    [ export_file, page_ids.uniq, exercise_ids.uniq ]
  end

  def create_cnx_export_file(filename, page_ids)
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
          .joins(chapter: :book)
          .where(id: page_ids)

        ordered_find_in_batches(
          pages, [ :url, Content::Models::Book.arel_table[:title].as('book_title') ]
        ) do |pgs|
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

  def create_exercises_export_file(filename, exercise_ids)
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
          .where(id: exercise_ids)

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
    order_bys = [ order_bys ].flatten
    no_alias_order_bys = order_bys.map { |col, _| col.is_a?(Arel::Nodes::As) ? col.left : col }
    relation = relation.dup.reorder(no_alias_order_bys).limit(batch_size)

    wheres = nil
    loop do
      records = relation.where(wheres || {}).to_a

      yield records

      break if records.size < batch_size

      last_record = records.last
      previous_eqs_array = []
      wheres = order_bys.map do |col, direction|
        method_name = case col
        when Arel::Nodes::As
          col.right
        when Arel::Attributes::Attribute
          col.name
        else
          col
        end
        arel_attribute = case col
        when Arel::Nodes::As
          col.left
        when Symbol
          relation.arel_table[col]
        else
          col
        end

        value = last_record.public_send(method_name)
        operator = direction.to_s.upcase == 'DESC' ? :lt : :gt

        clause = arel_attribute.public_send(operator, value)
        clause = clause.and(previous_eqs_array.reduce(:and)) unless previous_eqs_array.empty?
        previous_eqs_array << arel_attribute.eq(value)
        clause
      end.map { |arel| Arel::Nodes::Grouping.new arel }.reduce(:or)
    end
  end

end
