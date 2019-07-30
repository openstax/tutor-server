class Api::V1::Demo::Assign::TaskPlan::AssignedTo::Representer < Roar::Decorator
  include Roar::JSON
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  property :period,
           extend: Api::V1::Demo::Assign::TaskPlan::AssignedTo::PeriodRepresenter,
           class: Demo::Mash,
           readable: true,
           writeable: true

  property :opens_at,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :due_at,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
