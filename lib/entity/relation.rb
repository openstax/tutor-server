require 'entity'

class Entity
  class Relation < Entity

    # Expose all relation methods by default
    self._passthrough = true

    # The constructor for Entity::Relation only accepts an ActiveRecord::Relation object
    def initialize(repository)
      @repository = repository
    end

    # Same as ActiveRecord::Relation's inspect, but wraps entry class names
    def inspect
      return to_s if @repository.nil?

      entries = to_a.take([limit_value, 11].compact.min).map!(&:inspect)
      entries[10] = '...' if entries.size == 11

      "#<#{@repository.class.name} [#{entries.join(', ')}]>"
    end

  end
end
