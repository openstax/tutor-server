class SecureRandomTokenGenerator
  attr_reader :mode, :options

  def initialize(mode, options)
    @mode = mode
    @options = options
  end

  def run
    send("run_#{mode}")
  end

  def self.handled_modes
    [:hex, :urlsafe_base64, :base64, :random_number, :uuid]
  end

  private
  def run_hex
    strategy.hex(options[:length])
  end

  def run_base64
    strategy.base64(options[:length])
  end

  def run_urlsafe_base64
    strategy.urlsafe_base64(options[:length], options[:padding])
  end

  def run_random_number
    strategy.random_number(options[:maximum])
  end

  def run_uuid
    strategy.uuid
  end

  def strategy
    SecureRandom
  end

  TokenGenerator.register(self)
end
