require 'entity'

class Entity
  class Relation < Entity

    exposes :any?, :blank?, :eager_loading?, :empty?, :encode_with, :explain, :initialize_copy,
            :joined_includes_values, :load, :many?, :reload, :reset, :scoping, :size, :to_a,
            :to_sql, :uniq_value, :values, :where_values_hash, :exists?, :fifth, :fifth!, :find,
            :find_by, :find_by!, :first, :first!, :forty_two, :forty_two!, :fourth, :fourth!,
            :last, :last!, :second, :second!, :take, :take!, :third, :third!, :average,
            :calculate, :count, :ids, :maximum, :minimum, :pluck, :sum, :except, :merge, :only,
            :distinct, :eager_load, :extending, :from, :group, :having, :includes, :joins, :limit,
            :lock, :none, :offset, :order, :preload, :references, :reorder, :reverse_order,
            :rewhere, :select, :uniq, :unscope, :where, :find_each, :find_in_batches

    # The constructor for Entity::Relation only accepts an ActiveRecord::Relation object
    # The relation is set as readonly
    def initialize(repository)
      @repository = repository.readonly(true)
    end

    # Wrap ActiveRecord::Relation's inspect and pretty_print methods to use the Entity class names
    def inspect
      entries = to_a.take([repository.limit_value, 11].compact.min).map!(&:inspect)
      entries[10] = '...' if entries.size == 11

      "#<#{self.class.name} [#{entries.join(', ')}]>"
    end

    def pretty_print(q)
      q.pp(to_a)
    end

  end
end
