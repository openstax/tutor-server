require 'entity/common'

class Entity
  class Relation

    include Entity::Common

    def initialize(repository)
      @repository = repository
    end

    def inspect
      entries = to_a.take([limit_value, 11].compact.min).map!(&:inspect)
      entries[10] = '...' if entries.size == 11

      "#<#{self.class.name} [#{entries.join(', ')}]>"
    end

  end
end
