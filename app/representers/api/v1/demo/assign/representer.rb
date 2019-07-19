class Api::V1::Demo::Assign::Representer < Roar::Decorator
  include Representable::JSON::Hash
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  property :course,
           decorator: Api::V1::Demo::CourseRepresenter,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  collection :task_plans,
             extend: Api::V1::Demo::Assign::TaskPlan::Representer,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
