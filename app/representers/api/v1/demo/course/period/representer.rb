class Api::V1::Demo::Course::Period::Representer < Roar::Decorator
  include Roar::JSON

  property :name,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  collection :students,
             extend: Api::V1::Demo::Course::UserRepresenter,
             readable: true,
             writeable: true,
             schema_info: { required: true }
end
