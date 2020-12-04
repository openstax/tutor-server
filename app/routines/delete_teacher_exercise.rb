class DeleteTeacherExercise
  MIN_TEACHER_EXERCISE_NUMBER = 1000000

  lev_routine

  protected

  def exec(number:)
    raise "#{number} is not a teacher exercise number" if number < MIN_TEACHER_EXERCISE_NUMBER

    Content::Models::Exercise.where(number: number).update_all(deleted_at: Time.current)
  end
end
