class FillIReadingSpacedPracticeSlot

  lev_routine

  protected

  def exec(user, k_ago)
    outputs[:exercise_hash] = \
      OpenStax::Exercises::V1.fake_client.new_exercise_hash
    outputs[:exercise] = OpenStax::Exercises::V1::Exercise.new(
                           outputs[:exercise_hash].to_json
                         )
  end

end
