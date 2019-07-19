class Api::V1::Demo::Assign::TaskPlan::BookLocationRepresenter < Roar::Decorator
  include Representable::JSON::Hash
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  property :chapter,
           type: Integer,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :section,
           type: Integer,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
