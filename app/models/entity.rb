class Entity

  attr_reader :repository
  class_attribute :repository_class, :exposed_methods
  self.exposed_methods = []

  class << self
    def exposes(*methods)
      self.exposed_methods += methods
    end

    def method_missing(method_name, *arguments, &block)
      if exposed_methods.include?(method_name)
        result = repository_class.send(method_name, *arguments, &block)
        result.is_a?(repository_class) ? new(result) : result
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      if exposed_methods.include?(method_name)
        repository_class.respond_to?(method_name, include_private)
      else
        super
      end
    end

    protected :new
  end

  def method_missing(method_name, *arguments, &block)
    if exposed_methods.include?(method_name)
      result = repository.send(method_name, *arguments, &block)
      result.is_a?(repository_class) ? new(result) : result
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    if exposed_methods.include?(method_name)
      repository.respond_to?(method_name, include_private)
    else
      super
    end
  end

  delegate :id, to: :repository

  protected :repository, :repository_class, :exposed_methods

  protected

  def initialize(args = {})
    if args.is_a?(repository_class)
      @repository = args
    else
      @repository = repository_class.new(args)
    end
  end

end
