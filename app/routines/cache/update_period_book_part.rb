# NOTE: We currently do not support CLUes for Units because we only search for pages 1 level down
class Cache::UpdatePeriodBookPart
  lev_routine

  uses_routine :calculate_clue

  def exec(period:, book_part_uuid:, queue: 'dashboard')
    return if period.archived?

    student_role_ids = period.students.map(&:entity_role_id)

    uncached_role_book_part_ids = Cache::RoleBookPart.where(
      entity_role_id: student_role_ids, book_part_uuid: book_part_uuid, is_cached_for_period: false
    ).lock.pluck(:id)

    return if uncached_role_book_part_ids.empty?

    tasked_exercises = Tasks::Models::TaskedExercise.joins(
      task_step: [ :page, task: :taskings ]
    ).where(task_step: { task: { taskings: { entity_role_id: student_role_ids } } })

    responses = tasked_exercises.where(task_step: { page: { uuid: book_part_uuid } }).or(
      tasked_exercise.where(task_step: { page: { parent_book_part_uuid: book_part_uuid } })
    ).map(&:is_correct?)

    period_book_part = Cache::PeriodBookPart.new(
      period: period,
      book_part_uuid: book_part_uuid,
      clue: run(:calculate_clue, responses: responses).outputs.clue
    )

    Cache::RoleBookPart.where(
      id: uncached_role_book_part_ids
    ).update_all(is_cached_for_period: true)

    Cache::PeriodBookPart.import [ period_book_part ], validate: false, on_duplicate_key_update: {
      conflict_target: [ :course_membership_period_id, :book_part_uuid ], columns: [ :clue ]
    }
  end
end
