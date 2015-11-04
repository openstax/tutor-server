class TokenGenerator
  @@token_generators = {}

  def self.generator_for(mode)
    mode = mode.keys.first if mode.respond_to?(:keys)
    @@token_generators[mode] || (raise UnhandledTokenGeneratorMode, mode)
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
