require 'entity'

class Entity
  module ActiveRecord
    module Base
      module ClassMethods

        # Lists the Entity that wraps this class
        # Required for automatic wrapping
        def wrapped_by(entity_class)
          entity_class._wrapped_classes[self.name] = entity_class
        end

      end
    end
  end
end

::ActiveRecord::Base.extend Entity::ActiveRecord::Base::ClassMethods
