class Api::V1::Demo::Course::Representer < Roar::Decorator
  include Roar::JSON

  property :course_id,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  collection :teachers,
             extend: Api::V1::Demo::Course::UserRepresenter,
             readable: true,
             writeable: true,
             schema_info: { required: true }

  collection :periods,
             extend: Api::V1::Demo::Course::Period::Representer,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
