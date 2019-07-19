class Api::V1::Demo::Work::Representer < Roar::Decorator
  include Representable::JSON::Hash
  include Representable::Hash::AllowSymbols
  include Representable::Coercion

  property :course,
           decorator: Api::V1::Demo::CourseRepresenter,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :task_plans,
           extend: Api::V1::Demo::Work::TaskPlanRepresenter,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
