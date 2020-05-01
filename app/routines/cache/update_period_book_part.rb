# NOTE: We currently do not support CLUes for Units because we only search for pages 1 level down
class Cache::UpdatePeriodBookPart
  lev_routine

  uses_routine CalculateClue

  def exec(period:, book_part_uuid:, is_page: nil)
    return if period.archived?

    student_role_ids = period.students.map(&:entity_role_id)

    is_page = Content::Models::Page.where(uuid: book_part_uuid).exists? if is_page.nil?
    page_key = is_page ? :uuid : :parent_book_part_uuid

    responses = Tasks::Models::TaskedExercise.joins(
      task_step: [ :page, task: :taskings ]
    ).where(
      task_step: {
        task: { taskings: { entity_role_id: student_role_ids } },
        page: { page_key => book_part_uuid }
      }
    ).map(&:is_correct?)

    period_book_part = Cache::PeriodBookPart.new(
      period: period,
      book_part_uuid: book_part_uuid,
      is_page: is_page,
      clue: run(:calculate_clue, responses: responses).outputs.clue
    )

    Cache::PeriodBookPart.import [ period_book_part ], validate: false, on_duplicate_key_update: {
      conflict_target: [ :course_membership_period_id, :book_part_uuid ], columns: [ :clue ]
    }
  end
end
