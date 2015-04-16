require 'entity/common'
require 'entity/relation'

class Entity

  include Entity::Common

  cattr_reader :_wrapped_classes, :_unwrapped_classes
  @@_wrapped_classes = {}
  @@_unwrapped_classes = {}

  class_attribute :_repository_class, :_exposed_methods
  self._exposed_methods = Set.new

  class << ActiveRecord::Base
    def wrapped_by(entity_class)
      entity_class.wraps(self)
    end
  end

  class << self
    def exposes(*methods)
      self._exposed_methods += methods
    end

    def wraps(klass)
      self._repository_class = klass
      _wrapped_classes[klass.name] ||= self
      _unwrapped_classes[name] ||= klass
      exposes(klass.respond_to?(:primary_key) ? klass.primary_key.to_sym : :id)
    end

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

        return obj unless obj.respond_to?(:each_with_object)

        obj.each_with_object(obj.class.new) do |(k, v), o|
          v.nil? ? o << _wrap(k) : o[_wrap(k)] = _wrap(v)
        end
      end
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
    elsif args.is_a?(self.class)
      @repository = args._repository
    elsif _exposed_methods.include?(:new)
      @repository = _repository_class.new(_unwrap(args))
    else
      raise ArgumentError, "When initializing #{self.class}, you must pass either #{_repository_class} or another #{self.class} as an argument."
    end
  end

  def inspect
    repository.inspect.gsub(_repository_class.name, self.class.name)
  end

end
