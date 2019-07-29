class Api::V1::Demo::Assign::Representer < Roar::Decorator
  include Roar::JSON
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  property :course,
           extend: Api::V1::Demo::CourseRepresenter,
           class: Hashie::Mash,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  collection :task_plans,
             extend: Api::V1::Demo::Assign::TaskPlan::Representer,
             class: Hashie::Mash,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
