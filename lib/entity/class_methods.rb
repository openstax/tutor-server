require 'entity'

class Entity
  module ClassMethods

    # Lists the Entity that wraps this class
    # Required for automatic wrapping
    def wrapped_by(entity_class)
      entity_class._wrapped_classes[self.name] = entity_class
    end

  end
end
