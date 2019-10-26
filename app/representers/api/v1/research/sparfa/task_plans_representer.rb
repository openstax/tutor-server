class Api::V1::Research::Sparfa::TaskPlansRepresenter < Roar::Decorator
  include Representable::JSON::Collection

  items extend: Api::V1::Research::Sparfa::TaskPlanRepresenter
end
