class SecureRandomTokenGenerator
  def self.handled_modes
    [:hex, :urlsafe_base64, :base64, :random_number, :uuid]
  end

  def self.generate_with(mode)
    if mode.respond_to?(:keys)
      send("generate_#{mode.keys.first}", mode.values.first)
    else
      send("generate_#{mode}")
    end
  end

  private
  def self.generate_hex(options = {})
    strategy.send(:hex, options[:length])
  end

  def self.generate_base64(options = {})
    strategy.send(:base64, options[:length])
  end

  def self.generate_urlsafe_base64(options = {})
    strategy.send(:urlsafe_base64, options[:length], options[:padding])
  end

  def self.generate_random_number(options = {})
    strategy.send(:random_number, options[:maximum])
  end

  def self.generate_uuid(options = {})
    strategy.send(:uuid)
  end

  def self.strategy
    SecureRandom
  end

  TokenGenerator.register(self)
end
