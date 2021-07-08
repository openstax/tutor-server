class Api::V1::Demo::Course::UserRepresenter < Api::V1::Demo::UserRepresenter
  property :deleted?,
           as: :is_dropped,
           type: Virtus::Attribute::Boolean,
           readable: true,
           writeable: true
end
