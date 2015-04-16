require 'entity/relation'

class Entity

  cattr_reader :_wrapped_classes, :_unwrapped_classes
  @@_wrapped_classes = {}
  @@_unwrapped_classes = {}

  class_attribute :_repository_class, :_exposed_methods
  self._exposed_methods = [:id]

  attr_reader :repository
  protected :repository

  class << ActiveRecord::Base
    def wrapped_by(entity_class)
      entity_class._repository_class ||= self
      entity_class._wrapped_classes[self.name] ||= entity_class
      entity_class._unwrapped_classes[entity_class.name] ||= self
    end
  end

  class << self
    def wraps(klass)
      self._repository_class = klass
      self._wrapped_classes[klass.name] ||= self
      self._unwrapped_classes[name] ||= klass
    end

    def exposes(*methods)
      self._exposed_methods += methods
    end

    def _unwrap(obj)
      case obj
      when Entity, Entity::Relation
        obj._repository
      when Class
        _unwrapped_classes[obj.name]
      else
        obj
      end
    end

    def _wrap(obj)
      wrapper = case obj
      when ActiveRecord::Relation
        Entity::Relation
      when Class
        _wrapped_classes[obj.name]
      else
        _wrapped_classes[obj.class.name]
      end

      wrapper.nil? ? obj : wrapper.new(obj)
    end

    def method_missing(method_name, *arguments, &block)
      if _exposed_methods.include?(method_name)
        args = arguments.collect { |arg| _unwrap(arg) }
        result = _repository_class.send(method_name, *args, &block)
        _wrap(result)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      if _exposed_methods.include?(method_name)
        _repository_class.respond_to?(method_name, include_private)
      else
        super
      end
    end
  end

  def initialize(args = {})
    if args.is_a?(_repository_class)
      @repository = args
    else
      @repository = _repository_class.new(args)
    end
  end

  def _repository
    repository
  end

  def method_missing(method_name, *arguments, &block)
    if _exposed_methods.include?(method_name)
      args = arguments.collect { |arg| self.class._unwrap(arg) }
      result = repository.send(method_name, *args, &block)
      self.class._wrap(result)
    else
      super
    end
  end

  def respond_to_missing?(method_name, include_private = false)
    if _exposed_methods.include?(method_name)
      repository.respond_to?(method_name, include_private)
    else
      super
    end
  end

end
