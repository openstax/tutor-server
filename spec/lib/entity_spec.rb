require 'rails_helper'

RSpec.describe Entitee, type: :lib do
  class DummyEntitee < Entitee
  end

  class AnotherDummyEntitee < Entitee
  end

  class Dummy
    extend Entitee::ClassMethods

    wrapped_by DummyEntitee

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
    extend Entitee::ClassMethods

    attr_accessor :type

    wrapped_by do |instance|
      case instance.type
      when 'another'
        AnotherDummyEntitee
      else
        DummyEntitee
      end
    end
  end

  class DummyEntitee < Entitee
    wraps Dummy, AnotherDummy

    exposes :class_id, :find, :new, from_class: Dummy
    exposes :instance_id, :related_dummy
  end

  class AnotherDummyEntitee < Entitee
    wraps AnotherDummy
  end

  let(:dummy_instance) { Dummy.new }
  let(:dummy_entitee)   { DummyEntitee.new dummy_instance }

  it 'remembers which classes are wrapped by which entities' do
    expect(Entitee._wrap_class_procs[Dummy.name].call(dummy_instance)).to eq DummyEntitee
    expect(Entitee._unwrapped_classes[DummyEntitee.name]).to include(Dummy)
  end

  it 'can expose instance and class methods' do
    expect(DummyEntitee).to respond_to :class_id
    expect(DummyEntitee.class_id).to eq Dummy.class_id

    expect(dummy_entitee).to respond_to :instance_id
    expect(dummy_entitee.instance_id).to eq dummy_instance.instance_id
  end

  it 'automatically wraps classes' do
    expect(DummyEntitee).to respond_to :find
    found = DummyEntitee.find
    expect(found).to be_a DummyEntitee
    expect(found._repository).not_to eq dummy_instance

    expect(dummy_entitee).to respond_to :related_dummy
    related = dummy_entitee.related_dummy
    expect(related).to be_a DummyEntitee
    expect(related._repository).not_to eq dummy_instance
  end

  it 'can expose the new method' do
    expect(DummyEntitee).to respond_to :new
    dummy_entitee_2 = DummyEntitee.new(dummy_instance)
    expect(dummy_entitee_2).to be_a DummyEntitee
    expect(dummy_entitee_2._repository).to eq dummy_instance

    dummy_entitee_3 = DummyEntitee.new(test: true)
    expect(dummy_entitee_3._repository).not_to eq dummy_instance
    expect(dummy_entitee_3._repository.init).to eq(test: true)
  end

  it 'is equal to another entitee if the repository is equal' do
    dummy_entitee_2 = DummyEntitee.new(dummy_instance)
    expect(dummy_entitee).to eq dummy_entitee_2
    expect(dummy_entitee == dummy_entitee_2).to eq true
    expect(dummy_entitee.eql? dummy_entitee_2).to eq true
    expect(dummy_entitee.equal? dummy_entitee_2).to eq false
  end

  it 'can wrap multiple classes and a class can be wrapped by multiple entities' do
    entitee_1 = DummyEntitee.new(dummy_instance)
    expect(entitee_1._repository).to be_a(Dummy)

    another_dummy_instance = AnotherDummy.new
    entitee_2 = DummyEntitee.new(another_dummy_instance)
    expect(entitee_2._repository).to be_a(AnotherDummy)

    entitee_3 = Entitee._wrap(another_dummy_instance)
    expect(entitee_3).to be_a(DummyEntitee)

    another_dummy_instance.type = 'another'
    entitee_4 = Entitee._wrap(another_dummy_instance)
    expect(entitee_4).to be_a(AnotherDummyEntitee)
  end
end
