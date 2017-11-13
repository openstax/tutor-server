require 'entitee'

class Entitee
  class Relation < Entitee

    include Enumerable

    exposes :any?, :blank?, :eager_loading?, :empty?, :encode_with, :explain, :initialize_copy,
            :joined_includes_values, :load, :many?, :reload, :reset, :scoping, :size, :to_a,
            :to_sql, :uniq_value, :values, :where_values_hash, :exists?, :fifth, :fifth!, :find,
            :find_by, :find_by!, :first, :first!, :forty_two, :forty_two!, :fourth, :fourth!,
            :last, :last!, :second, :second!, :take, :take!, :third, :third!, :average, :calculate,
            :count, :ids, :maximum, :minimum, :pluck, :sum, :except, :merge, :only, :distinct,
            :eager_load, :extending, :from, :group, :having, :includes, :joins, :limit, :lock,
            :none, :offset, :order, :preload, :references, :reorder, :reverse_order, :rewhere,
            :select, :uniq, :unscope, :where, :find_each, :find_in_batches, :to_xml, :to_yaml,
            :length, :to_ary, :join, :table_name, :quoted_table_name, :primary_key,
            :quoted_primary_key, :connection, :columns_hash

    # The constructor for Entitee::Relation only accepts an ActiveRecord::Relation object
    def initialize(repository)
      # Don't dup the repository relation, since that's a huge performance hit
      @repository = repository
    end

    # Enumerable API
    def each(&block)
      to_a.each(&block)
    end

    # Wrap ActiveRecord::Relation's inspect and pretty_print methods to use the Entitee class names
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
