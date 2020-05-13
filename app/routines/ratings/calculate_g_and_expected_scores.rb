class Ratings::CalculateGAndExpectedScores
  lev_routine

  def exec(record:, exercise_group_book_parts:)
    outputs.g_array = exercise_group_book_parts.map do |exercise_group_book_part|
      1.0/Math.sqrt(1.0 + 3.0*(exercise_group_book_part.glicko_phi**2)/(Math::PI**2))
    end

    outputs.expected_score_array =
      exercise_group_book_parts.each_with_index.map do |exercise_group_book_part, index|
      1.0/(
        1.0 + Math.exp(
          -outputs.g_array[index] * (record.glicko_mu - exercise_group_book_part.glicko_mu)
        )
      )
    end
  end
end
