require 'rails_helper'

class Entity
  RSpec.describe ClassMethods, type: :lib do
    class DummyClass
      extend Entity::ClassMethods
    end

    class DummyEntityClass < Entity
    end

    it 'adds wrapped_by to classes that extend it' do
      expect(DummyClass).to respond_to(:wrapped_by)
      DummyClass.wrapped_by DummyEntityClass
      expect(Entity._wrapped_classes[DummyClass.name]).to eq DummyEntityClass
    end
  end
end
