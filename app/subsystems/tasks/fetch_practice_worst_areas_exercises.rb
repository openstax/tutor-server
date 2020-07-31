class Tasks::FetchPracticeWorstAreasExercises
  lev_routine express_output: :exercises, transaction: :read_committed

  def exec(student:, max_num_exercises: FindOrCreatePracticeTaskRoutine::NUM_EXERCISES)
    outputs.exercises = []

    ecosystem = student.course.ecosystem

    return if ecosystem.nil?

    role = student.role
    page_uuids = Ratings::RoleBookPart.where(
      role: role, is_page: true
    ).order(:updated_at).sort_by do |role_book_part|
      role_book_part.clue['is_real'] ? role_book_part.clue['most_likely'] : 1.5
    end.first(max_num_exercises).map(&:book_part_uuid)

    exercise_ids_by_page_uuid = ecosystem
      .pages
      .where(uuid: page_uuids)
      .pluck(:uuid, :practice_widget_exercise_ids)
      .to_h

    pools = page_uuids.map { |page_uuid| exercise_ids_by_page_uuid[page_uuid] }.reject(&:blank?)
    num_pools = pools.size

    return if num_pools == 0

    exercises_per_pool, remainder = max_num_exercises.divmod num_pools

    exercises_by_id = Content::Models::Exercise.where(id: pools.flatten).index_by(&:id)

    current_time = Time.current
    pools.each_with_index do |pool, index|
      exercises = filter_and_choose_exercises(
        exercises: exercises_by_id.values_at(*pool),
        role: role,
        count: exercises_per_pool + (remainder.to_f/(num_pools - index)).ceil,
        additional_excluded_numbers: outputs.exercises.map(&:number),
        current_time: current_time
      )

      remainder += exercises_per_pool - exercises.size

      outputs.exercises.concat exercises
    end
  end

  protected

  def filter_and_choose_exercises(
    exercises:,
    role:,
    count:,
    additional_excluded_numbers: [],
    current_time: Time.current
  )
    outs = FilterExcludedExercises.call(
      exercises: exercises,
      role: role,
      additional_excluded_numbers: additional_excluded_numbers,
      current_time: current_time
    ).outputs

    ChooseExercises[
      exercises: outs.exercises,
      role: role,
      count: count,
      already_assigned_exercise_numbers: outs.already_assigned_exercise_numbers
    ]
  end
end
