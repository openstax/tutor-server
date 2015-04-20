class Entity

  # Keep track of which AR classes are wrapped by which Entities and vice-versa
  cattr_reader :_wrapped_classes, :_unwrapped_classes
  @@_wrapped_classes = {}
  @@_unwrapped_classes = {}

  class << ActiveRecord::Base
    # Lists the Entity that wraps this class for autoload purposes
    def wrapped_by(entity_class)
      entity_class.wraps(self)
    end
  end

  class << self
    # Lists class methods that are part of the API
    def class_exposes(*method_names)
      method_names.each do |method_name|
        if method_name == :new
          # The `new` method requires special handling
          define_method(:initialize) do |args = {}|
            if args.is_a?(self.class._repository_class)
              @repository = args
            elsif args.is_a?(self.class)
              @repository = args._repository
            else
              @repository = self.class._repository_class.new(_unwrap(args))
            end
          end
        else
          # Define a method that delegates to the repository class
          define_singleton_method(method_name) do |*arguments, &block|
            args = _unwrap(arguments)
            result = _repository_class.send(method_name, *args, &block)
            _wrap(result)
          end
        end
      end
    end

    # Lists instance methods that are part of the API
    def instance_exposes(*method_names)
      method_names.each do |method_name|
        # Define a method that delegates to the repository object
        define_method(method_name) do |*arguments, &block|
          args = self.class._unwrap(arguments)
          result = repository.send(method_name, *args, &block)
          self.class._wrap(result)
        end
      end
    end

    # Lists the class that is wrapped by this Entity
    def wraps(klass)
      _wrapped_classes[klass.name] ||= self
      _unwrapped_classes[name] ||= klass
      instance_exposes(klass.respond_to?(:primary_key) ? klass.primary_key.to_sym : :id)
    end

    # Returns the class being wrapped by this Entity class
    # For internal use only
    def _repository_class
      _unwrapped_classes[name]
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
    else
      raise ArgumentError, "When initializing #{self.class}, you must pass either #{
                           self.class._repository_class} or another #{self.class} as an argument."
    end
  end

  # Entities are equal if the repositories are equal
  def ==(other)
    repository == self.class._unwrap(other)
  end

  # Entities are equal if the repositories are equal
  def eql?(other)
    repository.eql? self.class._unwrap(other)
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

end

require 'entity/relation'
