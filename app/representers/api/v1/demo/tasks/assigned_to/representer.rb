class Api::V1::Demo::Tasks::AssignedTo::Representer < Roar::Decorator
  include Roar::JSON

  property :period,
           type: String,
           readable: true,
           writeable: true

  property :opens_at,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }

  property :due_at,
           type: String,
           readable: true,
           writeable: true,
           schema_info: { required: true }
end
