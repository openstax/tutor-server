class Api::V1::Demo::Work::StatusRepresenter < Roar::Decorator
  include Roar::JSON

  property :username,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :progress_percent,
           type: Integer,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :correct_percent,
           type: Integer,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
