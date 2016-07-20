require 'rails_helper'

class Entity
  RSpec.describe Relation, type: :lib do
    let(:exercise)        { 5.times.map { FactoryGirl.create(:content_exercise) } }
    let(:relation)        { Content::Models::Exercise.all }
    let(:entity_relation) { Entity::Relation.new(relation) }

    it 'responds to all ActiveRecord::Relation methods that do not modify records' do
      [
        :any?, :blank?, :eager_loading?, :empty?, :encode_with, :explain, :joined_includes_values,
        :load, :many?, :reload, :reset, :scoping, :size, :to_a, :to_sql, :uniq_value, :values,
        :where_values_hash, :exists?, :fifth, :fifth!, :find, :find_by, :find_by!, :first, :first!,
        :forty_two, :forty_two!, :fourth, :fourth!, :last, :last!, :second, :second!, :take,
        :take!, :third, :third!, :average, :calculate, :count, :ids, :maximum, :minimum, :pluck,
        :sum, :except, :merge, :only, :distinct, :eager_load, :extending, :from, :group, :having,
        :includes, :joins, :limit, :lock, :none, :offset, :order, :preload, :references, :reorder,
        :reverse_order, :rewhere, :select, :uniq, :unscope, :where, :find_each, :find_in_batches
      ].each do |method_name|
        expect(entity_relation).to respond_to(method_name)

        next unless entity_relation.method(method_name).arity == 0
        expect(entity_relation.send method_name).to eq(Entity._wrap(relation.send method_name))
      end

    end

    it 'returns a properly formatted string from inspect' do
      expect(entity_relation.inspect).to(
        eq(relation.inspect.gsub('ActiveRecord::Relation', 'Entity::Relation')
                           .gsub('Content::Models::Exercise',
                                 'Content::Strategies::Direct::Exercise'))
      )
    end
  end
end
