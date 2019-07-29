class Api::V1::Demo::Work::Representer < Roar::Decorator
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
             extend: Api::V1::Demo::Work::TaskPlanRepresenter,
             class: Hashie::Mash,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
