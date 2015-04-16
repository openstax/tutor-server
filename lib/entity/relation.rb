require 'entity'

class Entity
  class Relation

    attr_reader :repository
    protected :repository

    def initialize(repository)
      @repository = repository
    end

    def _repository
      repository
    end

    def method_missing(method_name, *arguments, &block)
      if repository.respond_to?(method_name, true)
        args = arguments.collect { |arg| Entity._unwrap(arg) }
        result = repository.send(method_name, *args, &block)
        Entity._wrap(result)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      repository.respond_to?(method_name, include_private) || super
    end

  end
end
