class Api::V1::Demo::Tasks::BookLocationRepresenter < Roar::Decorator
  include Roar::JSON

  property :chapter,
           type: Integer,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :section,
           type: Integer,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
