class DeleteTeacherExercise
  lev_routine

  protected

  def exec(number:)
    updated = Content::Models::Exercise.where(number: number).where.not(
      user_profile_id: 0
    ).update_all(deleted_at: Time.current)

    raise "Invalid number: #{number}" if updated == 0
  end
end
