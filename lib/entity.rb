class Entity

  # Keep track of which AR classes are wrapped by which Entities and vice-versa
  cattr_reader :_wrapped_classes, :_unwrapped_classes
  @@_wrapped_classes = {}
  @@_unwrapped_classes = {}

  # Keep track of which methods are exposed from the Entity
  class_attribute :_exposed_methods, :_passthrough
  self._exposed_methods = Set.new

  class << ActiveRecord::Base
    # Lists the Entity that wraps this class for autoload purposes
    def wrapped_by(entity_class)
      entity_class.wraps(self)
    end
  end

  class << self
    # Lists methods that are part of the API
    def exposes(*methods)
      self._exposed_methods += methods
    end

    # Lists the class that is wrapped by this Entity
    def wraps(klass)
      _wrapped_classes[klass.name] ||= self
      _unwrapped_classes[name] ||= klass
      exposes(klass.respond_to?(:primary_key) ? klass.primary_key.to_sym : :id)
    end

    # Wraps the given object using Entity classes
    # For internal use only
    def _wrap(obj)
      case obj
      when ActiveRecord::Relation
        Entity::Relation.new(obj)
      when Class
        _wrapped_classes[obj.name] || obj
      when String
        _wrapped_classes[obj].try(:name) || obj
      else
        wrapper = _wrapped_classes[obj.class.name]
        return wrapper.new(obj) unless wrapper.nil?

        # Handle Enumerables
        return obj unless obj.respond_to?(:each_with_object) && obj.respond_to?(:clear)

        obj.each_with_object(obj.dup.clear) do |(k, v), o|
          v.nil? ? o << _wrap(k) : o[_wrap(k)] = _wrap(v)
        end
      end
    end

    # Unwraps the given object if it is an Entity class
    # For internal use only
    def _unwrap(obj)
      case obj
      when Entity, Entity::Relation
        obj._repository
      when Class
        _unwrapped_classes[obj.name] || obj
      when String
        _unwrapped_classes[obj].try(:name) || obj
      else
        return obj unless obj.respond_to?(:each_with_object)

        obj.each_with_object(obj.class.new) do |(k, v), o|
          v.nil? ? o << _unwrap(k) : o[_unwrap(k)] = _unwrap(v)
        end
      end
    end

    # Returns the class being wrapped by this Entity class
    # For internal use only
    def _repository_class
      _unwrapped_classes[name]
    end

    # Delegates exposed class methods to the repository class
    def method_missing(method_name, *arguments, &block)
      if _passthrough || _exposed_methods.include?(method_name)
        args = _unwrap(arguments)
        result = _repository_class.send(method_name, *args, &block)
        _wrap(result)
      else
        super
      end
    end

    # Delegates respond_to? to the repository class for exposed methods
    def respond_to_missing?(method_name, include_private = false)
      if _passthrough || _exposed_methods.include?(method_name)
        _repository_class.respond_to?(method_name, include_private)
      else
        super
      end
    end
  end

  # The instance object being wrapped
  attr_reader :repository
  protected :repository

  # Either initializes the Entity with an existing repository object,
  # or forwards the given arguments to the object's new method (if :new is exposed)
  def initialize(args = {})
    if args.is_a?(self.class._repository_class)
      @repository = args
    elsif args.is_a?(self.class)
      @repository = args._repository
    elsif _passthrough || _exposed_methods.include?(:new)
      @repository = self.class._repository_class.new(_unwrap(args))
    else
      raise ArgumentError, "When initializing #{self.class}, you must pass either #{
                           self.class._repository_class} or another #{self.class} as an argument."
    end
  end

  # Entities are equal if the repositories are equal
  def ==(other)
    repository == Entity._unwrap(other)
  end

  # Entities are equal if the repositories are equal
  def eql?(other)
    repository.eql? Entity._unwrap(other)
  end

  # Returns a new Entity of the same class that delegates all instance methods to the repository
  def passthrough
    new_entity = self.class.new(@repository)
    new_entity._passthrough = true
    new_entity
  end

  # Calls the repository's inspect method, but replaces its class name with the Entity's class name
  def inspect
    repository.inspect.gsub(self.class._repository_class.name, self.class.name)
  end

  # The object being wrapped
  # For internal use only
  def _repository
    repository
  end

  # Delegates exposed instance methods to the repository
  def method_missing(method_name, *arguments, &block)
    if _passthrough || _exposed_methods.include?(method_name)
      args = self.class._unwrap(arguments)
      result = repository.send(method_name, *args, &block)
      self.class._wrap(result)
    else
      super
    end
  end

  # Delegates respond_to? to the repository for exposed methods
  def respond_to_missing?(method_name, include_private = false)
    if _passthrough || _exposed_methods.include?(method_name)
      repository.respond_to?(method_name, include_private)
    else
      super
    end
  end

end

require 'entity/relation'
