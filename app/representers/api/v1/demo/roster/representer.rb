class Api::V1::Demo::Roster::Representer < Roar::Decorator
  include Roar::JSON

  property :course_id,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  collection :teachers,
             extend: Api::V1::Demo::Roster::UserRepresenter,
             readable: true,
             writeable: true,
             schema_info: { required: true }

  collection :periods,
             extend: Api::V1::Demo::Roster::Period::Representer,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
