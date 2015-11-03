class BabblerTokenGenerator < TokenGenerator
  def self.handles_mode?(mode)
    mode.to_sym == :memorable
  end

  def self.generate_with(mode)
    Babbler.babble
  end
end
