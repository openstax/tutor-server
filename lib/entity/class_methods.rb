require 'entity'

class Entity
  module ClassMethods

    # Lists the Entity that wraps this class
    # Argument can be either an Entity class or a block that
    # accepts an instance of this class and returns an appropriate Entity class
    # Required for automatic wrapping
    def wrapped_by(entity_class = nil, &block)
      Entity._wrap_class_procs[self.name] = block || lambda { |instance| entity_class }

      define_method :wrap do
        Entity._wrap(self)
      end
    end

  end
end
