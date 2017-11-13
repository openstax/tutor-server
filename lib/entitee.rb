class Entitee

  # Class methods

  # Keep track of which AR classes are wrapped by which Entities and vice-versa
  cattr_reader :_wrap_class_procs, :_unwrapped_classes
  @@_wrap_class_procs = Hash.new
  @@_unwrapped_classes = Hash.new { |hash, key| hash[key] = [] }

  class << self
    # Lists class and instance methods that are part of the API
    # If the :from_class option is specified, class methods are exposed
    # Otherwise, instance methods are exposed
    # Not thread-safe: call only during initialization
    def exposes(*method_names)
      options = method_names.last.is_a?(Hash) ? method_names.pop : {}
      klass = options[:from_class]

      if klass.nil?
        # Instance method
        method_names.each do |method_name|
          # Define a method that delegates to the repository object
          define_method(method_name) do |*arguments, &block|
            args = self.class._unwrap(arguments)
            result = repository.send(method_name, *args, &block)
            self.class._wrap(result)
          end
        end
      else
        # Class method
        method_names.each do |method_name|
          if method_name == :new
            # The `new` method requires special handling
            define_method(:initialize) do |args = {}|
              if self.class._repository_classes.include?(args.class)
                @repository = args
              else
                @repository = klass.new(self.class._unwrap(args))
              end
            end
          else
            # Define a method that delegates to the repository class
            define_singleton_method(method_name) do |*arguments, &block|
              args = _unwrap(arguments)
              result = klass.send(method_name, *args, &block)
              _wrap(result)
            end
          end
        end
      end
    end

    # Lists the classes that are wrapped by this Entitee
    # Required for the Entitee to function
    # Not thread-safe: call only during initialization
    def wraps(*klasses)
      _unwrapped_classes[name] += klasses

      exposes(
        *klasses.map do |klass|
          klass.respond_to?(:primary_key) ? klass.primary_key.to_sym : :id
        end.uniq
      )
    end

    # Returns the classes being wrapped by this Entitee class
    # For internal use only
    def _repository_classes
      _unwrapped_classes[name]
    end

    # Wraps the given object using Entitee classes
    # For internal use only
    def _wrap(obj)
      case obj
      when ::ActiveRecord::Relation
        Entitee::Relation.new(obj)
      else
        wrap_class_proc = _wrap_class_procs[obj.class.name]
        return wrap_class_proc.call(obj).new(obj) unless wrap_class_proc.nil?

        # Handle Enumerables
        return obj unless obj.is_a?(Enumerable)

        wrapped_obj = obj.map{ |element| _wrap(element) }
        obj.is_a?(Hash) ? wrapped_obj.to_h : wrapped_obj
      end
    end

    # Unwraps the given object if it is an Entitee class
    # For internal use only
    def _unwrap(obj)
      case obj
      when Entitee, Entitee::Relation
        obj._repository
      else
        # Handle Enumerables
        return obj unless obj.is_a?(Enumerable)

        unwrapped_obj = obj.map{ |element| _unwrap(element) }
        obj.is_a?(Hash) ? unwrapped_obj.to_h : unwrapped_obj
      end
    end
  end

  # Instance methods

  # The instance object being wrapped
  attr_reader :repository
  protected :repository

  # Either initializes the Entitee with an existing repository object,
  # or forwards the given arguments to the object's new method (if :new is exposed)
  def initialize(args = {})
    if self.class._repository_classes.include?(args.class)
      @repository = args
    elsif self.class._repository_classes.empty?
      raise IllegalState, "#{self.class.name} does not wrap any classes.", caller
    else
      raise ArgumentError, "When initializing #{self.class.name}, you must pass either #{
                           self.class._repository_classes.to_a.join(', ')} or another #{
                           self.class.name} as an argument.", caller
    end
  end

  # Entities are equal if the repositories are equal
  def ==(other)
    repository == self.class._unwrap(other)
  end

  # Hash key equality
  def eql?(other)
    repository.eql? self.class._unwrap(other)
  end

  # Hash function
  def hash
    repository.hash ^ self.class.hash
  end

  # Calls the repository's inspect method, but replaces its class name with the Entitee's class name
  def inspect
    repository.inspect.gsub(repository.class.name, self.class.name)
  end

  # The object being wrapped
  # For internal use only
  def _repository
    repository
  end

end

require 'entitee/class_methods'
require 'entitee/relation'

::ActiveRecord::Base.extend Entitee::ClassMethods
