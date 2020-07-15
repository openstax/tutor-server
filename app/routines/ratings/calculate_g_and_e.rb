# http://www.glicko.net/glicko/glicko2.pdf
class Ratings::CalculateGAndE
  lev_routine

  def exec(record:, opponents:)
    outputs.g_array = opponents.map do |opponent|
      1.0/Math.sqrt(1.0 + 3.0*(opponent.glicko_phi**2)/(Math::PI**2))
    end

    outputs.e_array = opponents.each_with_index.map do |opponent, index|
      1.0/(
        1.0 + Math.exp(
          -outputs.g_array[index] * (record.glicko_mu - opponent.glicko_mu)
        )
      )
    end
  end
end
