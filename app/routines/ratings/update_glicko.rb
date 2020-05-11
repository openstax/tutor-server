class Ratings::UpdateGlicko
  RATING_PERIOD = 1.week

  # Glicko system constant, between 0.3 and 1.2
  # Higher values == more volatile ratings
  TAU = 0.5

  # Glicko convergence tolerance
  EPSILON = 1e-6

  lev_routine

  uses_routine Ratings::CalculateGAndExpectedScores, as: :calculate_g_and_e

  def exec(record:, exercise_group_book_parts:, current_time: Time.current)
    unless record.updated_at.nil?
      num_ratings_periods = ((current_time - record.updated_at)/RATING_PERIOD).floor

      num_ratings_periods.times do
        record.glicko_phi = Math.sqrt(record.glicko_phi**2 + record.glicko_sigma**2)
      end
    end

    out = run(
      :calculate_g_and_e, record: record, exercise_group_book_parts: exercise_group_book_parts
    ).outputs

    estimated_variance = 1.0/(
      out.expected_score_array.each_with_index.map do |expected_score, index|
        (out.g_array[index]**2) * expected_score * (1 - expected_score)
      end.sum
    )

    index = 0
    scaled_response_deviation = exercise_group_book_parts.map do |exercise_group_book_part|
      g = out.g_array[index]
      expected_score = out.expected_score_array[index]
      index += 1

      g * ((exercise_group_book_part.response ? 1.0 : 0.0) - expected_score)
    end.sum

    estimated_improvement = estimated_variance * scaled_response_deviation

    phi_squared = record.glicko_phi**2
    gradient = estimated_improvement**2 - phi_squared - estimated_variance
    a = Math.log(record.glicko_sigma**2)

    f = ->(x) do
      exp_x = Math.exp(x)

      (
        exp_x * (gradient - exp_x)/(2.0 * (phi_squared + estimated_variance + exp_x)**2)
      ) - (x - a)/TAU**2
    end

    if gradient > 0
      b = Math.log(gradient)
      f_b = f.call(b)
    else
      k = 1
      k += 1 while (f_b = f.call(b = a - k*TAU)) < 0
    end

    f_a = f.call(a)

    while (b - a).abs > EPSILON do
      c = a + (a - b)*f_a/(f_b - f_a)

      f_c = f.call(c)

      if f_c*f_b < 0
        a = b
        f_a = f_b
      else
        f_a = f_a/2.0
      end

      b = c
      f_b = f_c
    end

    outputs.sigma = Math.exp(a/2.0)

    phi_star = Math.sqrt(phi_squared + outputs.sigma**2)

    outputs.phi = 1.0/Math.sqrt(1.0/(phi_star**2) + 1.0/estimated_variance)

    outputs.mu = record.glicko_mu + outputs.phi**2 * scaled_response_deviation
  end
end
