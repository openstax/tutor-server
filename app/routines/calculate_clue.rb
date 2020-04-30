class CalculateClue
  # The Z-score of the desired alpha, i.e. the tail of the interval with the desired confidence
  # Reference a Z-score table to adjust this
  # In this case we want a 50% confidence interval (which is pretty bad)
  # So alpha = 0.5 => 1 - alpha/2 = 0.75 => z = 0.68 (from the table)
  CLUE_Z_ALPHA = 0.68
  CLUE_Z_ALPHA_SQUARED = CLUE_Z_ALPHA**2
  CLUE_MIN_NUM_RESPONSES = 3

  lev_routine express_output: :clue

  def exec(responses:)
    num_responses = responses.size

    outputs.clue = if num_responses >= CLUE_MIN_NUM_RESPONSES
      num_correct = responses.count { |bool| bool }

      # Agresti-Coull method of statistical inference for the binomial distribution

      # n_hat is the modified number of trials
      n_hat = num_responses + CLUE_Z_ALPHA_SQUARED
      # p_hat is the modified estimate of the probability of success
      p_hat = (num_correct + 0.5 * CLUE_Z_ALPHA_SQUARED)/n_hat

      # Agresti-Coull confidence interval
      interval_delta = CLUE_Z_ALPHA * Math.sqrt(p_hat*(1.0 - p_hat)/n_hat)

      # The Agresti-Coull confidence interval can apparently go outside [0, 1], so we fix that
      {
        minimum: [p_hat - interval_delta, 0.0].max,
        most_likely: p_hat,
        maximum: [p_hat + interval_delta, 1.0].min,
        is_real: true
      }
    else
      {
        minimum: 0.0,
        most_likely: 0.5,
        maximum: 1.0,
        is_real: false
      }
    end
  end
end
