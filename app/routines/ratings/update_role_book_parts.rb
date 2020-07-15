# NOTE: We currently do not support CLUes for Units because we only search for pages 1 level down
class Ratings::UpdateRoleBookParts
  MIN_NUM_RESULTS = 3

  lev_routine transaction: :read_committed, job_class: LevJobReturningJob

  uses_routine Ratings::UpdateGlicko, as: :update_glicko
  uses_routine Ratings::CalculateGAndE, as: :calculate_g_and_e

  protected

  def exec(role:, task:, run_at_due:, queue: 'dashboard', wait: false, current_time: Time.current)
    current_time = Time.parse(current_time) if current_time.is_a?(String)

    if run_at_due &&
       Delayed::Worker.delay_jobs &&
       !task.past_due?(current_time: current_time)
      # This is the due date job but the task's due date changed. Try again later.
      job = self.class.set(queue: queue, run_at: task.due_at).perform_later(
        role: role, task: task, run_at_due: true, queue: queue, wait: wait
      )

      task.update_attribute :role_book_part_job_id, job.provider_job_id

      return
    end

    course_member = role.course_member
    return if course_member.nil? || course_member.deleted?

    period = course_member.try(:period)
    return if period.nil? || period.archived?

    course = period.course
    update_exercises = !course.is_preview && !course.is_test && !role.profile.account.is_test

    exercise_steps = task.exercise_steps
    pages_by_id = Content::Models::Page.select(:id, :uuid, :parent_book_part_uuid)
                                       .where(id: exercise_steps.map(&:content_page_id).uniq)
                                       .index_by(&:id)
    completed_exercise_steps = exercise_steps.filter(&:completed?)
    tasked_exercises_by_id = Tasks::Models::TaskedExercise
      .select(
        :id,
        :answer_ids,
        :correct_answer_id,
        :answer_id,
        :grader_points,
        :last_graded_at,
        '"content_exercises"."group_uuid"'
      )
      .joins(:exercise)
      .where(id: completed_exercise_steps.map(&:tasked_id))
      .preload(task_step: { task: { task_plan: :grading_template } })
      .filter(&:feedback_available?)
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

    role_book_parts = []
    exercise_group_book_parts = []
    exercise_steps_by_page_uuid.each do |page_uuid, exercise_steps|
      tasked_exercises = tasked_exercises_by_id.values_at(*exercise_steps.map(&:tasked_id)).compact

      new_role_book_part, new_exercise_group_book_parts = update_role_book_part(
        role: role,
        book_part_uuid: page_uuid,
        tasked_exercises: tasked_exercises,
        is_page: true,
        update_exercises: update_exercises,
        wait: wait,
        current_time: current_time
      )

      role_book_parts << new_role_book_part
      exercise_group_book_parts.concat new_exercise_group_book_parts
    end
    exercise_steps_by_parent_book_part_uuid.each do |parent_book_part_uuid, exercise_steps|
      tasked_exercises = tasked_exercises_by_id.values_at(*exercise_steps.map(&:tasked_id)).compact

      new_role_book_part, new_exercise_group_book_parts = update_role_book_part(
        role: role,
        book_part_uuid: parent_book_part_uuid,
        tasked_exercises: tasked_exercises,
        is_page: false,
        update_exercises: update_exercises,
        wait: wait,
        current_time: current_time
      )

      role_book_parts << new_role_book_part
      exercise_group_book_parts.concat new_exercise_group_book_parts
    end

    Ratings::RoleBookPart.import role_book_parts, validate: false, on_duplicate_key_update: {
      conflict_target: [ :entity_role_id, :book_part_uuid ],
      columns: [ :glicko_mu, :glicko_phi, :glicko_sigma, :tasked_exercise_ids, :clue ]
    }

    return unless update_exercises

    Ratings::ExerciseGroupBookPart.import exercise_group_book_parts, validate: false,
                                                                     on_duplicate_key_update: {
      conflict_target: [ :exercise_group_uuid, :book_part_uuid ],
      columns: [ :glicko_mu, :glicko_phi, :glicko_sigma, :tasked_exercise_ids ]
    }
  end

  def update_role_book_part(
    role:,
    book_part_uuid:,
    tasked_exercises:,
    is_page:,
    update_exercises:,
    wait:,
    current_time:
  )
    lock_statement = "FOR NO KEY UPDATE#{' NOWAIT' unless wait}"
    role_book_part = Ratings::RoleBookPart.lock(lock_statement).find_or_initialize_by(
      role: role, book_part_uuid: book_part_uuid
    ) { |role_book_part| role_book_part.is_page = is_page }

    used_tasked_exercise_ids = Set.new role_book_part.tasked_exercise_ids
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

    exercise_group_book_part_rel = Ratings::ExerciseGroupBookPart
    exercise_group_book_part_rel = exercise_group_book_part_rel.lock(
      lock_statement
    ) if update_exercises
    exercise_group_book_parts_by_group_uuid = exercise_group_book_part_rel.where(
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
      record: role_book_part,
      opponents: task_exercise_group_book_parts,
      update_opponents: update_exercises,
      current_time: current_time
    )

    role_book_part.tasked_exercise_ids += new_tasked_exercises.map(&:id)
    new_tasked_exercises.group_by(&:group_uuid).each do |exercise_group_uuid, tasked_exercises|
      exercise_group_book_parts_by_group_uuid[
        exercise_group_uuid
      ].tasked_exercise_ids += tasked_exercises.map(&:id)
    end if update_exercises

    role_book_part.clue = if role_book_part.num_results < MIN_NUM_RESULTS
      {
        minimum: 0.0,
        most_likely: 0.5,
        maximum: 1.0,
        is_real: false
      }
    else
      out = run(
        :calculate_g_and_e,
        record: role_book_part,
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

    [ role_book_part, task_exercise_group_book_parts ]
  end
end
