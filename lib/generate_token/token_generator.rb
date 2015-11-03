class TokenGenerator
  @@token_generators = []

  def self.inherited(base)
    @@token_generators << base
  end

  def self.selected_generator(mode)
    if generator = @@token_generators.select { |g| g.handles_mode?(mode) }.first
      generator
    else
      raise UnhandledTokenGeneratorMode
    end
  end

  class UnhandledTokenGeneratorMode < StandardError; end
end
