class TokenGenerator
  @@token_generators = {}

  def self.generator_for(mode)
    if generator = @@token_generators[mode]
      generator
    else
      raise UnhandledTokenGeneratorMode
    end
  end

  def self.register(generator)
    generator.handled_modes.each do |mode|
      raise TokenGeneratorModeAlreadyHandled if @@token_generators[mode]
      @@token_generators[mode] = generator
    end
  end

  class TokenGeneratorModeAlreadyHandled < StandardError; end
  class UnhandledTokenGeneratorMode < StandardError; end
end
