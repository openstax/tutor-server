# http://www.glicko.net/glicko/glicko2.pdf
class Ratings::UpdateGlicko
  RATING_PERIOD = 1.week

  # Glicko system constant, between 0.3 and 1.2
  # Higher values == more volatile ratings
  TAU = 0.5

  # Glicko convergence tolerance
  EPSILON = 1e-6

  lev_routine

  uses_routine Ratings::CalculateGAndE, as: :calculate_g_and_e

  def exec(record:, opponents:, update_opponents:, current_time: Time.current)
    unless record.updated_at.nil?
      num_ratings_periods = ((current_time - record.updated_at)/RATING_PERIOD).floor

      num_ratings_periods.times do
        record.glicko_phi = Math.sqrt(record.glicko_phi**2 + record.glicko_sigma**2)
      end
    end

    record_dup = record.dup if update_opponents

    update_glicko record: record, opponents: opponents, responses: opponents.map(&:response)

    return unless update_opponents

    opponents.each do |opponent|
      update_glicko(
        record: opponent,
        opponents: [ record_dup ],
        responses: [ !opponent.response ]
      )
    end
  end

  def update_glicko(record:, opponents:, responses:)
    out = run(:calculate_g_and_e, record: record, opponents: opponents).outputs

    v = 1.0/(
      out.e_array.each_with_index.map do |expected_score, index|
        (out.g_array[index]**2) * expected_score * (1 - expected_score)
      end.sum
    )

    index = 0
    scaled_score_surprises = opponents.map do |opponent|
      g = out.g_array[index]
      expected_score = out.e_array[index]
      match_response = responses[index]
      index += 1

      g * ((match_response ? 1.0 : 0.0) - expected_score)
    end
    delta_over_v = scaled_score_surprises.sum
    delta = v * delta_over_v

    phi_squared = record.glicko_phi**2
    gradient = delta**2 - phi_squared - v
    a = initial_a = Math.log(record.glicko_sigma**2)

    f = ->(x) do
      exp_x = Math.exp(x)

      (
        exp_x * (gradient - exp_x)/(2.0 * (phi_squared + v + exp_x)**2)
      ) - (x - initial_a)/TAU**2
    end

    if gradient > 0
      b = Math.log(gradient)
      f_b = f.call(b)
    else
      k = 1
      k += 1 while (f_b = f.call(b = initial_a - k*TAU)) < 0
    end

    f_a = f.call(initial_a)

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

    record.glicko_sigma = Math.exp(a/2.0)

    phi_star = Math.sqrt(phi_squared + record.glicko_sigma**2)

    record.glicko_phi = 1.0/Math.sqrt(1.0/(phi_star**2) + 1.0/v)

    record.glicko_mu = record.glicko_mu + record.glicko_phi**2 * delta_over_v
  end
end
