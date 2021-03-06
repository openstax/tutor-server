# NOTE: We currently do not support CLUes for Units because we only search for pages 1 level down
class Ratings::UpdatePeriodBookParts
  MIN_NUM_RESULTS = 3

  lev_routine transaction: :read_committed, job_class: LevJobReturningJob

  uses_routine Ratings::UpdateGlicko, as: :update_glicko
  uses_routine Ratings::CalculateGAndE, as: :calculate_g_and_e

  protected

  def exec(period:, task:, run_at_due:, queue: 'dashboard', wait: false, current_time: Time.current)
    return if period.nil? || period.archived?

    if run_at_due &&
       Delayed::Worker.delay_jobs &&
       !task.past_due?(current_time: current_time)
      # This is the due date job but the task's due date changed. Try again later.
      job = self.class.set(queue: queue, wait_until: task.due_at).perform_later(
        period: period, task: task, run_at_due: true, queue: queue, wait: wait
      )

      task.update_attribute :period_book_part_job_id, job.provider_job_id

      return
    end

    current_time = Time.parse(current_time) if current_time.is_a?(String)

    exercise_steps = task.exercise_steps
    pages_by_id = Content::Models::Page.select(:id, :uuid, :parent_book_part_uuid)
                                       .where(id: exercise_steps.map(&:content_page_id).uniq)
                                       .index_by(&:id)
    completed_exercise_steps = exercise_steps.filter(&:completed?)
    tasked_exercises_by_id = Tasks::Models::TaskedExercise
      .select(
        :id,
        :question_id,
        :answer_ids,
        :correct_answer_id,
        :answer_id,
        :grader_points,
        :last_graded_at,
        '"content_exercises"."group_uuid"'
      )
      .joins(:exercise)
      .where(id: completed_exercise_steps.map(&:tasked_id))
      .index_by(&:id)

    # Preload all available points
    task.exercise_and_placeholder_steps.each_with_index do |task_step, index|
      next unless task_step.exercise?

      tasked = tasked_exercises_by_id[task_step.tasked_id]
      next if tasked.nil?

      tasked.available_points = task.available_points_per_question_index[index]
    end

    exercise_steps_by_page_uuid = Hash.new { |hash, key| hash[key] = [] }
    exercise_steps_by_parent_book_part_uuid = Hash.new { |hash, key| hash[key] = [] }
    exercise_steps.each do |exercise_step|
      page = pages_by_id[exercise_step.content_page_id]
      exercise_steps_by_page_uuid[page.uuid] << exercise_step
      exercise_steps_by_parent_book_part_uuid[page.parent_book_part_uuid] << exercise_step
    end

    period_book_parts = exercise_steps_by_page_uuid.map do |page_uuid, exercise_steps|
      tasked_exercises = tasked_exercises_by_id.values_at(*exercise_steps.map(&:tasked_id)).compact
      update_period_book_part(
        period: period,
        book_part_uuid: page_uuid,
        tasked_exercises: tasked_exercises,
        is_page: true,
        wait: wait,
        current_time: current_time
      )
    end + exercise_steps_by_parent_book_part_uuid.map do |parent_book_part_uuid, exercise_steps|
      tasked_exercises = tasked_exercises_by_id.values_at(*exercise_steps.map(&:tasked_id)).compact
      update_period_book_part(
        period: period,
        book_part_uuid: parent_book_part_uuid,
        tasked_exercises: tasked_exercises,
        is_page: false,
        wait: wait,
        current_time: current_time
      )
    end

    Ratings::PeriodBookPart.import period_book_parts, validate: false, on_duplicate_key_update: {
      conflict_target: [ :course_membership_period_id, :book_part_uuid ],
      columns: [
        :glicko_mu,
        :glicko_phi,
        :glicko_sigma,
        :num_students,
        :tasked_exercise_ids,
        :clue
      ]
    }
  end

  def update_period_book_part(
    period:,
    book_part_uuid:,
    tasked_exercises:,
    is_page:,
    wait:,
    current_time:
  )
    period_book_part = Ratings::PeriodBookPart
      .lock("FOR NO KEY UPDATE#{' NOWAIT' unless wait}")
      .find_or_initialize_by(period: period, book_part_uuid: book_part_uuid) do |period_book_part|
      period_book_part.is_page = is_page
    end

    used_tasked_exercise_ids = Set.new period_book_part.tasked_exercise_ids
    new_tasked_exercises = tasked_exercises.reject do |tasked_exercise|
      used_tasked_exercise_ids.include? tasked_exercise.id
    end

    result_by_group_uuid = {}
    new_tasked_exercises.each do |tasked_exercise|
      result_by_group_uuid[tasked_exercise.group_uuid] = tasked_exercise.correctness
    end

    page_key = is_page ? :uuid : :parent_book_part_uuid
    exercise_group_uuids = (
      Content::Models::Exercise
        .joins(:page)
        .where(page: { page_key => book_part_uuid })
        .pluck(:group_uuid) + new_tasked_exercises.map(&:group_uuid)
    ).uniq

    exercise_group_book_parts_by_group_uuid = Ratings::ExerciseGroupBookPart.where(
      book_part_uuid: book_part_uuid
    ).index_by(&:exercise_group_uuid)
    exercise_group_uuids.each do |exercise_group_uuid|
      exercise_group_book_parts_by_group_uuid[exercise_group_uuid] ||=
        Ratings::ExerciseGroupBookPart.new(
          exercise_group_uuid: exercise_group_uuid,
          book_part_uuid: book_part_uuid,
          is_page: is_page
        )
    end

    task_exercise_group_book_parts = exercise_group_book_parts_by_group_uuid.values_at(
      *result_by_group_uuid.keys
    )
    task_exercise_group_book_parts.each do |exercise_group_book_part|
      exercise_group_book_part.result =
        result_by_group_uuid[exercise_group_book_part.exercise_group_uuid]
    end

    run(
      :update_glicko,
      record: period_book_part,
      opponents: task_exercise_group_book_parts,
      update_opponents: false,
      current_time: current_time
    )

    # Count students that answered at least 1 exercise in the target page
    period_book_part.num_students = CourseMembership::Models::Student
      .joins(role: { taskings: { task: { task_steps: :page } } })
      .where(
        course_membership_period_id: period.id,
        role: {
          taskings: {
            task: {
              task_steps: {
                tasked_type: 'Tasks::Models::TaskedExercise',
                page: { page_key => book_part_uuid }
              }
            }
          }
        }
      )
      .where.not(role: { taskings: { task: { task_steps: { first_completed_at: nil } } } })
      .distinct
      .count(:entity_role_id)
    period_book_part.tasked_exercise_ids += new_tasked_exercises.map(&:id)

    period_book_part.clue = if period_book_part.num_results < MIN_NUM_RESULTS
      {
        minimum: 0.0,
        most_likely: 0.5,
        maximum: 1.0,
        is_real: false
      }
    else
      out = run(
        :calculate_g_and_e,
        record: period_book_part,
        opponents: exercise_group_book_parts_by_group_uuid.values
      ).outputs

      num_scores = out.e_array.size
      mean = out.e_array.sum/num_scores

      {
        minimum: 0.0,
        most_likely: mean,
        maximum: 1.0,
        is_real: true
      }
    end

    period_book_part
  end
end
