# NOTE: We currently do not support CLUes for Units because we only search for pages 1 level down
class Cache::UpdateRoleBookPart
  lev_routine

  uses_routine CalculateClue

  def exec(role:, book_part_uuid:, current_time: Time.current, queue: 'dashboard')
    course_member = role.course_member
    return if course_member.nil? || course_member.deleted?

    period = course_member.try(:period)
    return if period.nil? || period.archived?

    tasked_exercises = Tasks::Models::TaskedExercise.joins(
      task_step: [ :page, task: :taskings ]
    ).where(task_step: { task: { taskings: { entity_role_id: role.id } } })

    is_page = Content::Models::Page.where(uuid: book_part_uuid).exists?
    page_key = is_page ? :uuid : :parent_book_part_uuid

    responses = Tasks::Models::TaskedExercise.joins(
      task_step: [ :page, task: :taskings ]
    ).where(
      task_step: {
        task: { taskings: { entity_role_id: role.id } }, page: { page_key => book_part_uuid }
      }
    ).filter do |tasked_exercise|
      tasked_exercise.task_step.task.feedback_available?(current_time: current_time)
    end.map(&:is_correct?)

    role_book_part = Cache::RoleBookPart.new(
      role: role,
      book_part_uuid: book_part_uuid,
      is_page: is_page,
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
