# NOTE: We currently do not support CLUes for Units because we only search for pages 1 level down
class Ratings::UpdatePeriodBookPart
  lev_routine

  uses_routine CalculateClue

  def exec(period:, book_part_uuid:, is_page: nil)
    return if period.archived?

    student_role_ids = period.students.map(&:entity_role_id)

    is_page = Content::Models::Page.where(uuid: book_part_uuid).exists? if is_page.nil?
    page_key = is_page ? :uuid : :parent_book_part_uuid

    tasked_exercises = Tasks::Models::TaskedExercise
      .select(
        :answer_ids,
        :correct_answer_id,
        :answer_id,
        :grader_points,
        '"tasks_taskings"."entity_role_id"'
      )
      .joins(task_step: [ :page, task: :taskings ])
      .where(
        task_step: {
          task: { taskings: { entity_role_id: student_role_ids } },
          page: { page_key => book_part_uuid }
        }
      )
      .where.not(answer_id: nil)
      .to_a

    period_book_part = Ratings::PeriodBookPart.new(
      period: period,
      book_part_uuid: book_part_uuid,
      is_page: is_page,
      num_students: tasked_exercises.map(&:entity_role_id).uniq.size,
      num_responses: tasked_exercises.size,
      clue: run(:calculate_clue, responses: tasked_exercises.map(&:is_correct?)).outputs.clue
    )

    Ratings::PeriodBookPart.import [ period_book_part ], validate: false, on_duplicate_key_update: {
      conflict_target: [ :course_membership_period_id, :book_part_uuid ],
      columns: [ :num_students, :num_responses, :clue ]
    }
  end
end
