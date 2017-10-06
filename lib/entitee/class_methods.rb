require 'entitee'

class Entitee
  module ClassMethods

    # Lists the Entitee that wraps this class
    # Argument can be either an Entitee class or a block that
    # accepts an instance of this class and returns an appropriate Entitee class
    # Required for automatic wrapping
    def wrapped_by(entity_class = nil, &block)
      Entitee._wrap_class_procs[self.name] = block || lambda { |instance| entity_class }

      define_method :wrap do
        Entitee._wrap(self)
      end
    end

  end
end
