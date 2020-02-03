class CalculateTaskStats

  lev_routine express_output: :stats

  protected

  def exec(tasks:, details: false)
    current_time = Time.current

    # Preload each task's student and period
    tasks = [tasks].flatten
    ActiveRecord::Associations::Preloader.new.preload(tasks, taskings: [ :period, role: :student ])

    tasks = tasks.reject do |task|
      task.taskings.all? do |tasking|
        period = tasking.period
        student = tasking.role.student

        period.nil? || period.archived? || student.nil? || student.dropped?
      end
    end
    task_ids = tasks.map(&:id)

    # Group tasks by period
    tasks_by_period = tasks.group_by do |task|
      periods = task.taskings.map(&:period).uniq
      raise(
        NotImplementedError, 'Each task in CalculateTaskStats must belong to exactly 1 period'
      ) if periods.size != 1

      periods.first
    end

    # Get unmapped cached Task stats (for the Task's original ecosystem)
    task_caches = Tasks::Models::TaskCache
      .select(:tasks_task_id, :student_ids, :student_names, :due_at, :as_toc)
      .joins(:task)
      .where(tasks_task_id: task_ids)
      .where('"tasks_task_caches"."content_ecosystem_id" = "tasks_tasks"."content_ecosystem_id"')
    task_cache_by_task_id = task_caches.index_by(&:tasks_task_id)

    # Get the page caches for each task
    pgs_by_task_id = {}
    task_caches.each do |task_cache|
      pgs_by_task_id[task_cache.tasks_task_id] = task_cache.as_toc[:books].flat_map do |bk|
        bk[:chapters].flat_map do |ch|
          ch[:pages].reject do |pg|
            pg[:num_assigned_exercises] == 0 && pg[:num_assigned_placeholders] == 0
          end.map do |pg|
            pg.merge(
              student_ids: task_cache.student_ids,
              student_names: task_cache.student_names,
              due_at: task_cache.due_at
            )
          end
        end
      end
    end

    # Populate the map of content by exercise id, if details have been requested
    content_by_exercise_id = if details
      exercise_ids = pgs_by_task_id.values.flatten.flat_map do |pg|
        pg[:exercises].map { |ex| ex[:id] }
      end

      Content::Models::Exercise.where(id: exercise_ids).pluck(:id, :content).to_h
    else
      {}
    end

    outputs.stats = tasks_by_period.map do |period, tasks|
      task_ids = tasks.map(&:id)
      task_caches = task_cache_by_task_id.values_at(*task_ids).compact

      total_count = task_caches.size
      started_task_caches = task_caches.select do |task_cache|
        task_cache.as_toc[:num_completed_steps] > 0
      end
      complete_count = started_task_caches.count do |task_cache|
        task_cache.as_toc[:num_completed_steps] == task_cache.as_toc[:num_assigned_steps]
      end
      partially_complete_count = started_task_caches.size - complete_count

      started_exercise_task_caches = started_task_caches.select do |task_cache|
        task_cache.as_toc[:num_completed_exercises] > 0
      end
      num_started_exercise_task_caches = started_exercise_task_caches.size
      mean_grade_percent = if num_started_exercise_task_caches == 0
        nil
      else
        grades_array = started_exercise_task_caches.map do |task_cache|
          task_cache.as_toc[:num_correct_exercises].to_f /
          task_cache.as_toc[:num_completed_exercises]
        end
        (grades_array.sum * 100.0 / num_started_exercise_task_caches).round
      end

      pgs = pgs_by_task_id.values_at(*task_ids)
                          .compact
                          .flatten
                          .sort_by { |pg| pg[:book_location] }
      total_students = pgs.flat_map { |pg| pg[:student_ids] }.uniq.size

      pg_groups = pgs.group_by { |pg| pg[:book_location] }
      spaced_pg_groups, current_pg_groups = pg_groups.partition do |book_location, pgs|
        pgs.all? { |pg| pg[:is_spaced_practice] }
      end

      # An assignment gets the trouble flag if any of its cnx page/modules
      # assigned to at least 25% of the class have a trouble flag.
      trouble = false
      current_page_stats = current_pg_groups.map do |book_location, pgs|
        generate_page_stats(
          pgs: pgs,
          details: details,
          content_by_exercise_id: content_by_exercise_id,
          current_time: current_time
        ).tap do |page_stats|
          trouble = true \
            if page_stats[:trouble] &&
               pgs.flat_map { |pg| pg[:student_ids] }.uniq.size >= 0.25 * total_students
        end
      end
      spaced_page_stats = spaced_pg_groups.map do |book_location, pgs|
        generate_page_stats(
          pgs: pgs,
          details: details,
          content_by_exercise_id: content_by_exercise_id,
          current_time: current_time
        ).tap do |page_stats|
          trouble = true \
            if page_stats[:trouble] &&
               pgs.flat_map { |pg| pg[:student_ids] }.uniq.size >= 0.25 * total_students
        end
      end

      {
        period_id: period.id,
        name: period.name,
        total_count: total_count,
        complete_count: complete_count,
        partially_complete_count: partially_complete_count,
        mean_grade_percent: mean_grade_percent,
        current_pages: current_page_stats,
        spaced_pages: spaced_page_stats,
        trouble: trouble
      }
    end.compact
  end

  def generate_page_stats(pgs:, details:, content_by_exercise_id:, current_time:)
    preferred_pg = pgs.first

    started_pgs = pgs.select { |pg| pg[:num_completed_exercises] > 0 }
    student_count = started_pgs.flat_map { |pg| pg[:student_ids] }.uniq.size
    assigned_count = pgs.map do |pg|
      pg[:num_assigned_exercises] + pg[:num_assigned_placeholders]
    end.sum
    completed_count = pgs.map { |pg| pg[:num_completed_exercises] }.sum
    correct_count = pgs.map { |pg| pg[:num_correct_exercises] }.sum
    incorrect_count = completed_count - correct_count

    # A cnx page-module gets the trouble flag if at least 50% of the total assigned questions for
    # this cnx page/module have been answered AND over 50% of the completed questions for this cnx
    # page/module are answered incorrectly OR after the due date AND less than 50% of the total
    # assigned questions for this cnx page/module have been answered.
    low_completion = completed_count < 0.5 * assigned_count
    past_due = !preferred_pg[:due_at].nil? && preferred_pg[:due_at] <= current_time
    low_performance = incorrect_count > correct_count
    trouble = low_completion ? past_due : low_performance

    {
      id: preferred_pg[:id],
      title: preferred_pg[:title],
      chapter_section: preferred_pg[:book_location],
      student_count: student_count,
      correct_count: correct_count,
      incorrect_count: incorrect_count,
      trouble: trouble
    }.tap do |stats|
      if details
        exs = pgs.flat_map { |pg| pg[:exercises].map { |ex| ex.merge pg.slice(:student_names) } }

        stats[:exercises] = exs.group_by { |ex| ex[:id] }.map do |exercise_id, exs|
          content = content_by_exercise_id[exercise_id]
          exs_by_question_id = exs.group_by { |ex| ex[:question_id] }

          {
            content: content,
            content_hash: JSON.parse(content),
            question_stats: exs.group_by { |ex| ex[:question_id] }.map do |question_id, exs|
              completed_exs = exs.select { |ex| ex[:completed] }
              selected_count_by_answer_id = Hash.new 0
              completed_exs.each { |ex| selected_count_by_answer_id[ex[:selected_answer_id]] += 1 }
              answer_stats = exs.first[:answer_ids].map do |answer_id|
                { answer_id: answer_id, selected_count: selected_count_by_answer_id[answer_id] }
              end
              answers = completed_exs.map do |ex|
                {
                  student_names: ex[:student_names],
                  free_response: ex[:free_response],
                  answer_id: ex[:selected_answer_id]
                }
              end

              {
                question_id: question_id,
                answered_count: completed_exs.size,
                answer_stats: answer_stats,
                answers: answers
              }
            end,
            average_step_number: exs.map { |ex| ex[:step_number] }.sum / exs.size
          }
        end.sort_by { |exercise_stats| exercise_stats[:average_step_number] }
      end
    end
  end

end
