class Tasks::FetchPracticeWorstAreasExercises
  lev_routine express_output: :exercises, transaction: :read_committed

  def exec(student:, max_num_exercises: FindOrCreatePracticeTaskRoutine::NUM_EXERCISES)
    outputs.exercises = []

    course = student.course
    ecosystem = course.ecosystem

    return if ecosystem.nil?

    role = student.role
    page_uuids = Ratings::RoleBookPart.where(
      role: role, is_page: true
    ).order(:updated_at).sort_by do |role_book_part|
      role_book_part.clue['is_real'] ? role_book_part.clue['most_likely'] : 1.5
    end.first(max_num_exercises).map(&:book_part_uuid)

    page_id_by_uuid = Content::Models::Page.where(uuid: page_uuids).pluck(:uuid, :id).to_h
    page_ids = page_id_by_uuid.values_at(*page_uuids)

    exercise_ids_by_page_id = ecosystem
      .pages
      .where(id: page_ids)
      .pluck(:id, :practice_widget_exercise_ids)
      .to_h

    # Add teacher-created exercises
    Content::Models::Exercise
      .where(content_page_id: page_ids, user_profile_id: course.related_teacher_profile_ids)
      .pluck(:content_page_id, :id)
      .group_by(&:first).each do |page_id, exercises|
      exercise_ids_by_page_id[page_id] ||= []
      exercise_ids_by_page_id.concat exercises
    end

    pools = exercise_ids_by_page_id.values_at(*page_ids).reject(&:blank?)
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
