class Api::V1::Demo::Tasks::Representer < Roar::Decorator
  include Roar::JSON

  property :course_id,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  collection :tasks,
             extend: Api::V1::Demo::Tasks::TaskRepresenter,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
