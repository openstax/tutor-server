class Api::V1::Demo::Course::UserRepresenter < Api::V1::Demo::UserRepresenter
  property :is_dropped,
           type: Virtus::Attribute::Boolean,
           readable: true,
           writeable: true
end
