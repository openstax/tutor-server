class SecureRandomTokenGenerator
  def self.handled_modes
    [:hex, :urlsafe_base64, :base64, :random_bytes, :random_number, :uuid]
  end

  def self.generate_with(mode)
    SecureRandom.send(mode)
  end

  TokenGenerator.register(self)
end
