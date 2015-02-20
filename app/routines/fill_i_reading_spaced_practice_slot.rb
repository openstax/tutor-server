class FillIReadingSpacedPracticeSlot

  lev_routine

  protected

  def exec(user, k_ago)
    # debugger
    OpenStax::Exercises::V1.fake_client.add_exercise
    exercise_hash = OpenStax::Exercises::V1.fake_client.exercises_array.last
    outputs[:exercise_hash] = exercise_hash
    outputs[:exercise] = OpenStax::Exercises::V1::Exercise.new(
                           exercise_hash[:content].to_json
                         )
  end

end
