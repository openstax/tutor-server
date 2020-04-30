# NOTE: We currently do not support CLUes for Units because we only search for pages 1 level down
class Cache::UpdateRoleBookPart
  lev_routine

  uses_routine :calculate_clue

  def exec(role:, book_part_uuid:, current_time: Time.current, queue: 'dashboard')
    course_member = role.course_member
    return if course_member.nil? || course_member.deleted?

    period = course_member.try(:period)
    return if period.nil? || period.archived?

    tasked_exercises = Tasks::Models::TaskedExercise.joins(
      task_step: [ :page, task: :taskings ]
    ).where(task_step: { task: { taskings: { entity_role_id: role.id } } })

    responses = tasked_exercises.where(task_step: { page: { uuid: book_part_uuid } }).or(
      tasked_exercise.where(task_step: { page: { parent_book_part_uuid: book_part_uuid } })
    ).preload(task_step: { task: :time_zone }).filter do |tasked_exercise|
      tasked_exercise.task_step.task.feedback_available?(current_time: current_time)
    end.map(&:is_correct?)

    role_book_part = Cache::RoleBookPart.new(
      role: role,
      book_part_uuid: book_part_uuid,
      clue: run(:calculate_clue, responses: responses).outputs.clue,
      is_cached_for_period: false
    )

    Cache::RoleBookPart.import [ role_book_part ], validate: false, on_duplicate_key_update: {
      conflict_target: [ :entity_role_id, :book_part_uuid ],
      columns: [ :clue, :is_cached_for_period ]
    }

    Cache::UpdatePeriodBookPart.set(queue: queue).perform_later(
      period: period, book_part_uuid: book_part_uuid
    )
  end
end