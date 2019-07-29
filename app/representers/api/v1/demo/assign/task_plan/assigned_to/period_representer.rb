class Api::V1::Demo::Assign::TaskPlan::AssignedTo::PeriodRepresenter < Roar::Decorator
  include Roar::JSON
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  property :name,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
