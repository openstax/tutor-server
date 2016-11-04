require 'rails_helper'

class Entity
  describe ClassMethods, type: :lib do
    class DummyClass
      extend Entity::ClassMethods
    end

    class DummyEntityClass < Entity
    end

    it 'adds wrapped_by to classes that extend it' do
      expect(DummyClass).to respond_to(:wrapped_by)
      DummyClass.wrapped_by DummyEntityClass
      expect(Entity._wrap_class_procs[DummyClass.name].call(DummyClass.new)).to eq DummyEntityClass
    end
  end
end
