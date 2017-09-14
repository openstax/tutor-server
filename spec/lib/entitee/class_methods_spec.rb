require 'rails_helper'

class Entitee
  describe ClassMethods, type: :lib do
    class DummyClass
      extend Entitee::ClassMethods
    end

    class DummyEntiteeClass < Entitee
    end

    it 'adds wrapped_by to classes that extend it' do
      expect(DummyClass).to respond_to(:wrapped_by)
      DummyClass.wrapped_by DummyEntiteeClass
      expect(Entitee._wrap_class_procs[DummyClass.name].call(DummyClass.new)).to eq DummyEntiteeClass
    end
  end
end
