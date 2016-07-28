class BabblerTokenGenerator
  def initialize(*args)
  end

  def run
    Babbler.babble
  end

  def self.handled_modes
    [:memorable, :babble, :babbler]
  end

  TokenGenerator.register(self)
end
