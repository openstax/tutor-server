class TokenGenerator
  @@token_generators = []

  def self.inherited(base)
    @@token_generators << base
  end

  def self.generator_for(mode)
    if generator = @@token_generators.select { |g| g.handled_modes.include?(mode) }.first
      generator
    else
      raise UnhandledTokenGeneratorMode
    end
  end

  class UnhandledTokenGeneratorMode < StandardError; end
end
