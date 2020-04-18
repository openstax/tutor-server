# NOTE: We currently do not support CLUes for Units because we only search for pages 1 level down
class Ratings::UpdateRoleBookPart
  lev_routine

  uses_routine CalculateClue

  def exec(role:, book_part_uuid:, is_page: nil, feedback_before: Time.current)
    feedback_before = Time.parse(feedback_before) if feedback_before.is_a?(String)

    course_member = role.course_member
    return if course_member.nil? || course_member.deleted?

    period = course_member.try(:period)
    return if period.nil? || period.archived?

    is_page = Content::Models::Page.where(uuid: book_part_uuid).exists? if is_page.nil?
    page_key = is_page ? :uuid : :parent_book_part_uuid

    responses = Tasks::Models::TaskedExercise
      .select(:id, :answer_id, :correct_answer_id)
      .joins(task_step: [ :page, task: :taskings ])
      .where(
        task_step: {
          task: { taskings: { entity_role_id: role.id } }, page: { page_key => book_part_uuid }
        }
      )
      .where.not(answer_id: nil)
      .filter do |tasked_exercise|
      tasked_exercise.task_step.task.auto_grading_feedback_available?(current_time: feedback_before)
    end.map(&:is_correct?)

    role_book_part = Ratings::RoleBookPart.new(
      role: role,
      book_part_uuid: book_part_uuid,
      is_page: is_page,
      num_responses: responses.size,
      clue: run(:calculate_clue, responses: responses).outputs.clue
    )

    Ratings::RoleBookPart.import [ role_book_part ], validate: false, on_duplicate_key_update: {
      conflict_target: [ :entity_role_id, :book_part_uuid ], columns: [ :num_responses, :clue ]
    }
  end
end
