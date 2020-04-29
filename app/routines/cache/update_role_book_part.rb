# NOTE: We currently do not support CLUes for Units because we only search for pages 1 level down
class Cache::UpdateRoleBookPart
  lev_routine

  def exec(role:, book_part_uuid:, queue: 'dashboard')
    tasked_exercises = Tasks::Models::TaskedExercise.joins(
      task_step: [ :page, task: :taskings ]
    ).where(task_step: { task: { taskings: { entity_role_id: role.id } } })

    tasked_exercises = tasked_exercises.where(task_step: { page: { uuid: book_part_uuid } }).or(
      tasked_exercise.where(task_step: { page: { parent_book_part_uuid: book_part_uuid } })
    )

    course_member = role.course_member
    return if course_member.nil? || course_member.deleted?

    period = course_member.try(:period)
    return if period.nil? || period.archived?

    Cache::UpdatePeriodBookPart.set(queue: queue).perform_later(
      period: period, book_part_uuid: book_part_uuid
    )
  end
end
