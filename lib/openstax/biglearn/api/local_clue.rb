class OpenStax::Biglearn::Api::LocalClue
  attr_reader :aggregate
  attr_reader :left
  attr_reader :right
  attr_reader :threshold
  attr_reader :level
  attr_reader :confidence

  attr_reader :responses

  def initialize(responses: [])
    @aggregate  = 0.5
    @left       = 0.0
    @right      = 1.0
    @threshold  = :below
    @level      = :medium
    @confidence = :bad

    @responses = responses

    self._update
  end

  def _update
    if responses.count >= 3
      trial_tot = responses.count
      trial_suc = responses.count{|response| response == 1.0}

      z_alpha = 0.68

      p_hat = (trial_suc + 0.5*z_alpha**2) / (trial_tot + z_alpha**2)

      var = responses.map{|value| (p_hat - value)**2}
                     .inject(&:+) / (responses.count - 1)

      interval = ( z_alpha * Math.sqrt(p_hat*(1-p_hat)/(trial_tot + z_alpha**2)) +
                   0.1*Math.sqrt(var) +
                   0.05 )

      @aggregate = p_hat
      @left  = [p_hat - interval, 0].max
      @right = [p_hat + interval, 1].min
    end

    if @aggregate < 0.3
      @level = :low
    elsif @aggregate < 0.8
      @level = :medium
    else
      @level = :high
    end

    if (@right-@left).abs <= 0.5
      @confidence = :good
    else
      @confidence = :bad
    end

    if responses.count > 3
      @threshold = :above
    else
      @threshold = :below
    end

    # puts "[#{@aggregate} #{@left} #{@right} #{@level} #{@confidence} #{@threshold}]"
  end
end
