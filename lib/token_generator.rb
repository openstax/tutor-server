module TokenGenerator
  @token_generators = {}

  class << self

    def generator_for(mode, options)
      if generator = @token_generators[mode]
        generator.new(mode, options)
      else
        raise UnhandledTokenGeneratorMode, mode
      end
    end

    # Not thread-safe: call only during initialization
    def register(generator)
      generator.handled_modes.each do |mode|
        (raise TokenGeneratorModeAlreadyHandled, mode) if @token_generators[mode]
        @token_generators[mode] = generator
      end
    end

  end

  class TokenGeneratorModeAlreadyHandled < StandardError; end
  class UnhandledTokenGeneratorMode < StandardError; end
end
