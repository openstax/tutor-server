class FillIReadingSpacedPracticeSlot

  lev_routine

  protected

  def exec()
    # debugger
    OpenStax::Exercises::V1.fake_client.add_exercise
    exercise_hash = OpenStax::Exercises::V1.fake_client.exercises_array.last
    outputs[:exercise_hash] = exercise_hash
  end

end
