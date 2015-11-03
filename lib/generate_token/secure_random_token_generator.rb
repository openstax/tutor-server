class SecureRandomTokenGenerator < TokenGenerator
  def self.handles_mode?(mode)
    [:hex, :urlsafe_base64, :base64,
     :random_bytes, :random_number, :uuid].include?(mode.to_sym)
  end

  def self.generate_with(mode)
    SecureRandom.send(mode)
  end
end
