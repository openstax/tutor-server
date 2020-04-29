# NOTE: We currently do not support CLUes for Units because we only search for pages 1 level down
class Cache::UpdatePeriodBookPart
  lev_routine

  def exec(period:, book_part_uuid:, queue: 'dashboard')
    tasked_exercises = Tasks::Models::TaskedExercise.joins(
      task_step: [ :page, task: { taskings: { role: :student } } ]
    ).where(task_step: { task: { taskings: { role: { student: { period: period } } } } })

    tasked_exercises = tasked_exercises.where(task_step: { page: { uuid: book_part_uuid } }).or(
      tasked_exercise.where(task_step: { page: { parent_book_part_uuid: book_part_uuid } })
    )

    
  end
end
