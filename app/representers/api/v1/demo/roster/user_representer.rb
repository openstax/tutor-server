class Api::V1::Demo::Roster::UserRepresenter < Roar::Decorator
  include Roar::JSON

  property :username,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :name,
           type: String,
           readable: true,
           writeable: true
end
