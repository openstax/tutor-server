require 'entity'

class Entity
  class Relation < Entity

    self._passthrough = true

    def initialize(repository)
      @repository = repository
    end

    def inspect
      return to_s if @repository.nil?

      entries = to_a.take([limit_value, 11].compact.min).map!(&:inspect)
      entries[10] = '...' if entries.size == 11

      "#<#{@repository.class.name} [#{entries.join(', ')}]>"
    end

  end
end
