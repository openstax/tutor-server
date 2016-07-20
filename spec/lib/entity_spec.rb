require 'rails_helper'

RSpec.describe Entity, type: :lib do
  class DummyEntity < Entity
  end

  class AnotherDummyEntity < Entity
  end

  class Dummy
    extend Entity::ClassMethods

    wrapped_by DummyEntity

    def self.class_id
      object_id
    end

    def self.find
      new
    end

    attr_reader :init

    def initialize(args = {})
      @init = args
    end

    def instance_id
      object_id
    end

    def related_dummy
      Dummy.new
    end
  end

  class AnotherDummy
    extend Entity::ClassMethods

    attr_accessor :type

    wrapped_by do |instance|
      case instance.type
      when 'another'
        AnotherDummyEntity
      else
        DummyEntity
      end
    end
  end

  class DummyEntity < Entity
    wraps Dummy, AnotherDummy

    exposes :class_id, :find, :new, from_class: Dummy
    exposes :instance_id, :related_dummy
  end

  class AnotherDummyEntity < Entity
    wraps AnotherDummy
  end

  let(:dummy_instance) { Dummy.new }
  let(:dummy_entity)   { DummyEntity.new dummy_instance }

  it 'remembers which classes are wrapped by which entities' do
    expect(Entity._wrap_class_procs[Dummy.name].call(dummy_instance)).to eq DummyEntity
    expect(Entity._unwrapped_classes[DummyEntity.name]).to include(Dummy)
  end

  it 'can expose instance and class methods' do
    expect(DummyEntity).to respond_to :class_id
    expect(DummyEntity.class_id).to eq Dummy.class_id

    expect(dummy_entity).to respond_to :instance_id
    expect(dummy_entity.instance_id).to eq dummy_instance.instance_id
  end

  it 'automatically wraps classes' do
    expect(DummyEntity).to respond_to :find
    found = DummyEntity.find
    expect(found).to be_a DummyEntity
    expect(found._repository).not_to eq dummy_instance

    expect(dummy_entity).to respond_to :related_dummy
    related = dummy_entity.related_dummy
    expect(related).to be_a DummyEntity
    expect(related._repository).not_to eq dummy_instance
  end

  it 'can expose the new method' do
    expect(DummyEntity).to respond_to :new
    dummy_entity_2 = DummyEntity.new(dummy_instance)
    expect(dummy_entity_2).to be_a DummyEntity
    expect(dummy_entity_2._repository).to eq dummy_instance

    dummy_entity_3 = DummyEntity.new(test: true)
    expect(dummy_entity_3._repository).not_to eq dummy_instance
    expect(dummy_entity_3._repository.init).to eq(test: true)
  end

  it 'is equal to another entity if the repository is equal' do
    dummy_entity_2 = DummyEntity.new(dummy_instance)
    expect(dummy_entity).to eq dummy_entity_2
    expect(dummy_entity == dummy_entity_2).to eq true
    expect(dummy_entity.eql? dummy_entity_2).to eq true
    expect(dummy_entity.equal? dummy_entity_2).to eq false
  end

  it 'can wrap multiple classes and a class can be wrapped by multiple entities' do
    entity_1 = DummyEntity.new(dummy_instance)
    expect(entity_1._repository).to be_a(Dummy)

    another_dummy_instance = AnotherDummy.new
    entity_2 = DummyEntity.new(another_dummy_instance)
    expect(entity_2._repository).to be_a(AnotherDummy)

    entity_3 = Entity._wrap(another_dummy_instance)
    expect(entity_3).to be_a(DummyEntity)

    another_dummy_instance.type = 'another'
    entity_4 = Entity._wrap(another_dummy_instance)
    expect(entity_4).to be_a(AnotherDummyEntity)
  end
end
