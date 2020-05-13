# NOTE: We currently do not support CLUes for Units because we only search for pages 1 level down
class Ratings::UpdatePeriodBookParts
  INITIAL_MU = 0.0
  INITIAL_PHI = 2.015
  INITIAL_SIGMA = 0.06

  MIN_NUM_RESPONSES = 3

  lev_routine

  uses_routine Ratings::UpdateGlicko, as: :update_glicko
  uses_routine Ratings::CalculateGAndE, as: :calculate_g_and_e

  protected

  def update_period_book_part(period:, book_part_uuid:, tasked_exercises:, is_page:, current_time:)
    period_book_part = Ratings::PeriodBookPart.find_or_initialize_by(
      period: period, book_part_uuid: book_part_uuid
    ) do |period_book_part|
      period_book_part.is_page = is_page
      period_book_part.tasked_exercise_ids = []
      period_book_part.glicko_mu = INITIAL_MU
      period_book_part.glicko_phi = INITIAL_PHI
      period_book_part.glicko_sigma = INITIAL_SIGMA
    end

    used_tasked_exercise_ids = Set.new period_book_part.tasked_exercise_ids
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
          glicko_mu: INITIAL_MU,
          glicko_phi: INITIAL_PHI,
          glicko_sigma: INITIAL_SIGMA
        )
    end

    task_exercise_group_book_parts = exercise_group_book_parts_by_group_uuid.values_at(
      *response_by_group_uuid.keys
    )
    task_exercise_group_responses = task_exercise_group_book_parts.map do |exercise_group_book_part|
      Hashie::Mash.new(
        exercise_group_book_part.attributes.slice('glicko_mu', 'glicko_phi', 'glicko_sigma')
      ).tap do |mash|
        mash.response = response_by_group_uuid[exercise_group_book_part.exercise_group_uuid]
      end
    end

    out = run(
      :update_glicko,
      record: period_book_part,
      exercise_group_book_parts: task_exercise_group_responses,
      current_time: current_time
    ).outputs

    period_book_part.glicko_mu = out.glicko_mu
    period_book_part.glicko_phi = out.glicko_phi
    period_book_part.glicko_sigma = out.glicko_sigma

    period_book_part.num_students = CourseMembership::Models::Student
      .joins(role: { taskings: { task: { task_steps: :page } } })
      .where(course_membership_period_id: period.id)
      .where(role: { taskings: { task: { task_steps: { page: { page_key => book_part_uuid } } } } })
      .distinct
      .pluck(:entity_role_id)
      .size
    period_book_part.tasked_exercise_ids += new_tasked_exercises.map(&:id)

    period_book_part.clue = if period_book_part.num_responses < MIN_NUM_RESPONSES
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
        exercise_group_book_parts: exercise_group_book_parts_by_group_uuid.values
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

  def exec(period:, task:, is_page: nil, current_time: Time.current)
    return if period.nil? || period.archived?

    current_time = Time.parse(current_time) if current_time.is_a?(String)

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

    period_book_parts = exercise_steps_by_page_uuid.map do |page_uuid, exercise_steps|
      tasked_exercises = tasked_exercises_by_id.values_at(*exercise_steps.map(&:tasked_id))
      update_period_book_part(
        period: period,
        book_part_uuid: page_uuid,
        tasked_exercises: tasked_exercises,
        is_page: true,
        current_time: current_time
      )
    end + exercise_steps_by_parent_book_part_uuid.map do |parent_book_part_uuid, exercise_steps|
      tasked_exercises = tasked_exercises_by_id.values_at(*exercise_steps.map(&:tasked_id))
      update_period_book_part(
        period: period,
        book_part_uuid: parent_book_part_uuid,
        tasked_exercises: tasked_exercises,
        is_page: false,
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
end
