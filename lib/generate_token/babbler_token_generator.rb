class BabblerTokenGenerator < TokenGenerator
  def self.handled_modes
    [:memorable, :babble, :babbler]
  end

  def self.generate_with(mode)
    Babbler.babble
  end
end
