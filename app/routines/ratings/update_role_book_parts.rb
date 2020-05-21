# NOTE: We currently do not support CLUes for Units because we only search for pages 1 level down
class Ratings::UpdateRoleBookParts
  MIN_NUM_RESPONSES = 3

  lev_routine

  uses_routine Ratings::UpdateGlicko, as: :update_glicko
  uses_routine Ratings::CalculateGAndE, as: :calculate_g_and_e

  protected

  def exec(role:, task:, current_time: Time.current)
    current_time = Time.parse(current_time) if current_time.is_a?(String)

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
      .select(:id, :answer_id, :correct_answer_id, '"content_exercises"."group_uuid"')
      .joins(:exercise)
      .where(id: completed_exercise_steps.map(&:tasked_id))
      .index_by(&:id)

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
    current_time:
  )
    role_book_part = Ratings::RoleBookPart.find_or_initialize_by(
      role: role, book_part_uuid: book_part_uuid
    ) { |role_book_part| role_book_part.is_page = is_page }

    used_tasked_exercise_ids = Set.new role_book_part.tasked_exercise_ids
    new_tasked_exercises = tasked_exercises.reject do |tasked_exercise|
      used_tasked_exercise_ids.include? tasked_exercise.id
    end

    response_by_group_uuid = {}
    new_tasked_exercises.each do |tasked_exercise|
      response_by_group_uuid[tasked_exercise.group_uuid] = tasked_exercise.is_correct?
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
      *response_by_group_uuid.keys
    )
    task_exercise_group_book_parts.each do |exercise_group_book_part|
      exercise_group_book_part.response =
        response_by_group_uuid[exercise_group_book_part.exercise_group_uuid]
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

    role_book_part.clue = if role_book_part.num_responses < MIN_NUM_RESPONSES
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
